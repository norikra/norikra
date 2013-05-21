require 'java'
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
      return if @targets.include?(target)
      open_target(target, fields)
    end

    def close(target)
      #TODO: write
      raise NotImplementedError
    end

    def reserve(target, field, type)
      @typedef_manager.reserve(target, field, type)
    end

    def register(query)
      unless @targets.includes?(query.target)
        open(target) # open as lazy defined target
      end
      register_query(query)
    end

    def deregister(query_name)
      #TODO: write
      raise NotImplementedError
    end

    def send(target, events)
      return unless @targets.includes?(target) # discard events for target not registered
      return if events.size < 1

      if @typedef_manager.lazy?(target)
        base_fieldset = @typedef_manager.generate_base_fieldset(target, events.first)
        register_base_fieldset(target, base_fieldset)
      end

      registered_data_fieldset = @registered_fieldsets[target][:data]

      events.each do |event|
        fieldset = @typedef_manager.refer(target, event)

        unless registered_data_fieldset[fieldset.summary]
          # register waiting queries including this fieldset, and this fieldset itself
          register_fieldset(target, fieldset)
        end
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
      @mutex.synchronize do
        return if @targets.include?(target)
        @typedef_manager.add_target(target, fields)
        @registered_fieldsets[target] = {:base => {}, :query => {}, :data => {}}

        unless @typedef_manager.lazy?(target)
          base_fieldset = @typedef_manager.base_fieldset(target)
          register_fieldset_actually(target, fieldset, :base)
        end

        @targets.push(target)
      end
    end

    def register_query(query)
      target = query.target
      @mutex.synchronize do
        if @typedef_manager.lazy?(target) || @typedef_manager.fields_defined?(target, query.fields)
          @waiting_queries[target] ||= []
          @waiting_queries[target].push(query)
        else
          query_fieldset = @typedef_manager.generate_query_fieldset(target, query.fields)
          @typedef_manager.bind_fieldset(target, :query, query_fieldset)
          register_fieldset_actually(target, query_fieldset, :query)
          register_query_actually(target, query)
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
          register_query_actually(target, query)
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

    def register_base_fieldset(target, fieldset)
      @mutex.synchronize do
        return unless @typedef_manager.lazy?(target)

        @typedef_manager.bind_fieldset(target, :base, fieldset)
        register_fieldset_actually(target, fieldset, :base)
        @typedef_manager.activate(target, fieldset)
      end
      nil
    end

    # this method should be protected with @mutex lock
    def register_query_actually(target, query)
      epl = @service.getEPAdministrator.createEPL(query.expression)
      epl.java_send :addListener, [com.espertech.esper.client.UpdateListener.java_class], Listener.new(query.name, @output_pool)
    end

    # this method should be protected with @mutex lock
    def register_fieldset_actually(target, fieldset, level)
      return if @registered_fieldsets[target][level][fieldset.summary]

      # Map Supertype (target) and Subtype (typedef name, like TARGET_TypeDefName)
      # http://esper.codehaus.org/esper-4.9.0/doc/reference/en-US/html/event_representation.html#eventrep-map-supertype
      # epService.getEPAdministrator().getConfiguration()
      #   .addEventType("AccountUpdate", accountUpdateDef, new String[] {"BaseUpdate"});
      case level
      when :base
        @config.addEventType(fieldset.event_type_name, fieldset.definition)
      when :query
        base_name = @typedef_manager.base_fieldset.event_type_name
        @config.addEventType(fieldset.event_type_name, fieldset.definition, [base_name].to_java(:string))
      else
        subset_names = @typedef_manager.subsets(target, fieldset).map(&:event_type_name)
        @config.addEventType(fieldset.event_type_name, fieldset.definition, subset_names.to_java(:string))
      end
      nil
    end
  end
end
