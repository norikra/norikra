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

      @waiting_queries = {} # target => [query]
    end

    def start
      @runtime = @service.getEPRuntime
    end

    def stop
      #TODO: stop to @runtime
    end

    def open(target, fields=nil)
      debug "opening target", :target => target, :fields => fields
      return false if @targets.include?(target)
      open_target(target, fields)
    end

    def close(target)
      debug "closing target", :target => target
      #TODO: write
      raise NotImplementedError
    end

    def reserve(target, field, type)
      @typedef_manager.reserve(target, field, type)
    end

    def register(query)
      unless @targets.include?(query.targets.first)
        open(query.targets.first) # open as lazy defined target
      end
      register_query(query)
    end

    def deregister(query_name)
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
        debug "opening lazy target", :target => target
        trace "generating base fieldset from event", :target => target, :event => events.first
        base_fieldset = @typedef_manager.generate_base_fieldset(target, events.first)
        trace "registering base fieldset", :target => target, :base => base_fieldset
        register_base_fieldset(target, base_fieldset)
        debug "target successfully opened with fieldset", :target => target, :base => base_fieldset
      end

      registered_data_fieldset = @registered_fieldsets[target][:data]

      events.each do |event|
        fieldset = @typedef_manager.refer(target, event)

        unless registered_data_fieldset[fieldset.summary]
          # register waiting queries including this fieldset, and this fieldset itself
          register_fieldset(target, fieldset)
        end
        #TODO: trace log
        #p "sendEvent eventType:#{fieldset.event_type_name}, event:#{event.inspect}"
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
        #TODO: trace log
        #p "updated event query:#{@query_name}, event:#{new_events.inspect}"
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
        # @typedef_manager.bind_fieldset(target, :base, fieldset)
        register_fieldset_actually(target, fieldset, :base)
      end
      nil
    end

    def register_query(query)
      #TODO: support JOINs
      target = query.targets.first
      @mutex.synchronize do
        if @typedef_manager.lazy?(target) || !@typedef_manager.fields_defined?(target, query.fields)
          @waiting_queries[target] ||= []
          @waiting_queries[target].push(query)
        else
          query_fieldset = @typedef_manager.generate_query_fieldset(target, query.fields)
          @typedef_manager.bind_fieldset(target, :query, query_fieldset)
          register_fieldset_actually(target, query_fieldset, :query)
          register_query_actually(target, query_fieldset.event_type_name, query)

          # replace registered data fieldsets with new fieldset inherits this query fieldset
          @typedef_manager.supersets(target, query_fieldset).each do |set|
            rebound = set.rebind
            register_fieldset_actually(target, rebound, :data, true) # replacing
            @typedef_manager.replace_fieldset(target, set, rebound)
            remove_fieldset_actually(target, set, :data)
          end
        end
        @queries.push(query)
      end
    end

    def register_waiting_queries(target)
      waitings = @waiting_queries.delete(target) || []
      not_registered = []

      waitings.each do |query|
        if @typedef_manager.fields_defined?(target, query.fields)
          query_fieldset = @typedef_manager.generate_query_fieldset(target, query.fields)
          @typedef_manager.bind_fieldset(target, :query, query_fieldset)
          register_fieldset_actually(target, query_fieldset, :query)
          register_query_actually(target, query_fieldset.event_type_name, query)
        else
          not_registered.push(query)
        end
      end

      @waiting_queries[target] = not_registered if not_registered.size > 0
    end

    def register_fieldset(target, fieldset)
      @mutex.synchronize do
        @typedef_manager.bind_fieldset(target, :data, fieldset)

        if @waiting_queries[target]
          register_waiting_queries(target)
        end

        register_fieldset_actually(target, fieldset, :data)
      end
    end

    # this method should be protected with @mutex lock
    def register_query_actually(target, stream_name, query)
      query = query.dup_with_stream_name(stream_name)
      epl = @service.getEPAdministrator.createEPL(query.expression)
      epl.java_send :addListener, [com.espertech.esper.client.UpdateListener.java_class], Listener.new(query.name, @output_pool)
      #TODO: debug log
      #p "addListener target:#{target}, query_name:#{query.name}, query:#{query.expression}"
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
        @config.addEventType(fieldset.event_type_name, fieldset.definition)
        #TODO: debug log
        #p "addEventType target:#{target}, level:base, eventType:#{fieldset.event_type_name}"
      when :query
        base_name = @typedef_manager.base_fieldset(target).event_type_name
        @config.addEventType(fieldset.event_type_name, fieldset.definition, [base_name].to_java(:string))
        #TODO: debug log
        #p "addEventType target:#{target}, level:query, eventType:#{fieldset.event_type_name}, base:#{base_name}"
      else
        subset_names = @typedef_manager.subsets(target, fieldset).map(&:event_type_name)
        @config.addEventType(fieldset.event_type_name, fieldset.definition, subset_names.to_java(:string))
        #TODO: debug log
        #p "addEventType target:#{target}, level:data, eventType:#{fieldset.event_type_name}, inherit:#{subset_names.join(',')}"

        @registered_fieldsets[target][level][fieldset.summary] = fieldset
      end
      nil
    end

    # this method should be protected with @mutex lock as same as register
    def remove_fieldset_actually(target, fieldset, level)
      return if level == :base || level == :query

      # DON'T check @registered_fieldsets[target][level][fieldset.summary]
      # removed fieldset should be already replaced with register_fieldset_actually w/ replace flag
      #TODO: debug log
      @config.removeEventType(fieldset.event_type_name, true)
    end
  end
end
