require 'java'

require 'norikra/logger'
include Norikra::Log

require 'esper-4.9.0.jar'
require 'esper/lib/commons-logging-1.1.1.jar'
require 'esper/lib/antlr-runtime-3.2.jar'
require 'esper/lib/cglib-nodep-2.2.jar'

require 'norikra/typedef_manager'

module Norikra
  class Engine
    attr_reader :targets, :queries, :output_pool, :typedef_manager

    def initialize(output_pool, typedef_manager=nil)
      @output_pool = output_pool
      @typedef_manager = typedef_manager || Norikra::TypedefManager.new()

      @service = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider
      @config = @service.getEPAdministrator.getConfiguration

      @mutex = Mutex.new

      # fieldsets already registered into @runtime
      @registered_fieldsets = {} # {target => {fieldset_summary => Fieldset}

      @targets = []
      @queries = []

      @waiting_queries = []
    end

    def start
      debug "norikra engine starting: creating esper runtime"
      @runtime = @service.getEPRuntime
      debug "norikra engine started"
    end

    def stop
      debug "stopping norikra engine: stop all statements on esper"
      @service.getEPAdministrator.stopAllStatements
      debug "norikra engine stopped"
    end

    def open(target, fields=nil)
      info "opening target", :target => target, :fields => fields
      return false if @targets.include?(target)
      open_target(target, fields)
    end

    def close(target)
      info "closing target", :target => target
      #TODO: write
      raise NotImplementedError
    end

    def reserve(target, field, type)
      @typedef_manager.reserve(target, field, type)
    end

    def register(query)
      info "registering query", :name => query.name, :targets => query.targets, :expression => query.expression
      query.targets.each do |target|
        open(target) unless @targets.include?(target)
      end
      register_query(query)
    end

    def deregister(query_name)
      info "de-registering query", :name => query_name
      #TODO: write
      raise NotImplementedError
    end

    def send(target, events)
      trace "send messages", :target => target, :events => events
      unless @targets.include?(target) # discard events for target not registered
        trace "messages skipped for non-opened target", :target => target
        return
      end
      return if events.size < 1

      if @typedef_manager.lazy?(target)
        info "opening lazy target", :target => target
        debug "generating base fieldset from event", :target => target, :event => events.first

        base_fieldset = @typedef_manager.generate_base_fieldset(target, events.first)

        debug "registering base fieldset", :target => target, :base => base_fieldset

        register_base_fieldset(target, base_fieldset)

        info "target successfully opened with fieldset", :target => target, :base => base_fieldset
      end

      registered_data_fieldset = @registered_fieldsets[target][:data]

      events.each do |event|
        fieldset = @typedef_manager.refer(target, event)

        unless registered_data_fieldset[fieldset.summary]
          # register waiting queries including this fieldset, and this fieldset itself
          debug "registering unknown fieldset", :target => target, :fieldset => fieldset

          register_fieldset(target, fieldset)

          debug "successfully registered"
        end

        trace "calling sendEvent", :target => target, :fieldset => fieldset, :event_type_name => fieldset.event_type_name, :event => event
        @runtime.sendEvent(@typedef_manager.format(target, event).to_java, fieldset.event_type_name)
      end
      nil
    end

    class Listener
      include com.espertech.esper.client.UpdateListener

      def initialize(query_name, output_pool)
        @query_name = query_name
        @output_pool = output_pool
      end

      def update(new_events, old_events)
        trace "updated event", :query => @query_name, :event => new_events
        @output_pool.push(@query_name, new_events)
      end
    end
    ##### Unmatched events are simply ignored
    # class UnmatchedListener
    #   include com.espertech.esper.client.UnmatchedListener
    #   def update(event)
    #     # puts "unmatched:\n- " + event.getProperties.inspect
    #     # ignore
    #   end
    # end

    private

    def open_target(target, fields)
      # from open
      @mutex.synchronize do
        return false if @targets.include?(target)
        @typedef_manager.add_target(target, fields)
        @registered_fieldsets[target] = {:base => {}, :query => {}, :data => {}}

        unless @typedef_manager.lazy?(target)
          base_fieldset = @typedef_manager.base_fieldset(target)

          @typedef_manager.bind_fieldset(target, :base, base_fieldset)
          register_fieldset_actually(target, base_fieldset, :base)
        end

        @targets.push(target)
      end
      true
    end

    def register_base_fieldset(target, fieldset)
      # for lazy target, with generated fieldset from sent events.first
      @mutex.synchronize do
        return false unless @typedef_manager.lazy?(target)

        @typedef_manager.activate(target, fieldset)
        register_fieldset_actually(target, fieldset, :base)
      end
      nil
    end

    def register_query(query)
      @mutex.synchronize do
        unless @typedef_manager.ready?(query)
          @waiting_queries.push(query)
          @queries.push(query)
          return
        end

        mapping = @typedef_manager.generate_fieldset_mapping(query)
        mapping.each do |target, query_fieldset|
          @typedef_manager.bind_fieldset(target, :query, query_fieldset)
          register_fieldset_actually(target, query_fieldset, :query)
        end
        register_query_actually(query, mapping)

        mapping.each do |target, query_fieldset|
          # replace registered data fieldsets with new fieldset inherits this query fieldset
          @typedef_manager.supersets(target, query_fieldset).each do |set|
            rebound = set.rebind(true) # update event_type_name with new inheritations

            register_fieldset_actually(target, rebound, :data, true) # replacing
            @typedef_manager.replace_fieldset(target, set, rebound)
            remove_fieldset_actually(target, set, :data)
          end
        end

        @queries.push(query)
      end
    end

    def register_waiting_queries(target)
      ready = []
      not_ready = []
      @waiting_queries.each do |q|
        if @typedef_manager.ready?(q)
          ready.push(q)
        else
          not_ready.push(q)
        end
      end
      @waiting_queries = not_ready

      ready.each do |query|
        mapping = @typedef_manager.generate_fieldset_mapping(query)
        mapping.each do |target, query_fieldset|
          @typedef_manager.bind_fieldset(target, :query, query_fieldset)
          register_fieldset_actually(target, query_fieldset, :query)
        end
        register_query_actually(query, mapping)
      end
    end

    def register_fieldset(target, fieldset)
      @mutex.synchronize do
        @typedef_manager.bind_fieldset(target, :data, fieldset)

        if @waiting_queries.size > 0
          register_waiting_queries(target)
        end

        register_fieldset_actually(target, fieldset, :data)
      end
    end

    # this method should be protected with @mutex lock
    def register_query_actually(query, mapping)
      # 'mapping' argument is {target => fieldset}
      event_type_name_map = {}
      mapping.keys.each do |key|
        event_type_name_map[key] = mapping[key].event_type_name
      end

      administrator = @service.getEPAdministrator

      statement_model = administrator.compileEPL(query.expression)
      Norikra::Query.rewrite_event_type_name(statement_model, event_type_name_map)

      epl = administrator.create(statement_model)
      epl.java_send :addListener, [com.espertech.esper.client.UpdateListener.java_class], Listener.new(query.name, @output_pool)
    end

    # this method should be protected with @mutex lock
    def register_fieldset_actually(target, fieldset, level, replace=false)
      return if level == :data && @registered_fieldsets[target][level][fieldset.summary] && !replace

      # Map Supertype (target) and Subtype (typedef name, like TARGET_TypeDefName)
      # http://esper.codehaus.org/esper-4.9.0/doc/reference/en-US/html/event_representation.html#eventrep-map-supertype
      # epService.getEPAdministrator().getConfiguration()
      #   .addEventType("AccountUpdate", accountUpdateDef, new String[] {"BaseUpdate"});
      case level
      when :base
        debug "add event type", :target => target, :level => 'base', :event_type => fieldset.event_type_name
        @config.addEventType(fieldset.event_type_name, fieldset.definition)
      when :query
        base_name = @typedef_manager.base_fieldset(target).event_type_name
        debug "add event type", :target => target, :level => 'query', :event_type => fieldset.event_type_name, :base => base_name
        @config.addEventType(fieldset.event_type_name, fieldset.definition, [base_name].to_java(:string))
      else
        subset_names = @typedef_manager.subsets(target, fieldset).map(&:event_type_name)
        debug "add event type", :target => target, :level => 'data', :event_type => fieldset.event_type_name, :inherit => subset_names
        @config.addEventType(fieldset.event_type_name, fieldset.definition, subset_names.to_java(:string))

        @registered_fieldsets[target][level][fieldset.summary] = fieldset
      end
      nil
    end

    # this method should be protected with @mutex lock as same as register
    def remove_fieldset_actually(target, fieldset, level)
      return if level == :base || level == :query

      # DON'T check @registered_fieldsets[target][level][fieldset.summary]
      # removed fieldset should be already replaced with register_fieldset_actually w/ replace flag
      debug "remove event type", :target => target, :event_type => fieldset.event_type_name
      @config.removeEventType(fieldset.event_type_name, true)
    end
  end
end
