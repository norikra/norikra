require 'java'
require 'esper-4.9.0.jar'
require 'esper/lib/commons-logging-1.1.1.jar'
require 'esper/lib/antlr-runtime-3.2.jar'
require 'esper/lib/cglib-nodep-2.2.jar'

require 'norikra/typedef_manager'

####TODO: add 'stream' keyword support

module Norikra
  class Engine
    attr_reader :targets, :queries, :output_pool, :typedef_manager

    def initialize(output_pool, typedef_manager=nil)
      @output_pool = output_pool
      @typedef_manager = typedef_manager || Norikra::TypedefManager.new()

      @service = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider
      @config = @service.getEPAdministrator.getConfiguration

      @mutex = Mutex.new

      # if @typedefs[target] exists, first data has already arrived.
      @typedefs = {} # target => {typedefname => definition}

      @targets = []
      @queries = []

      # Queries must be registered with typedef, but when no data reached, no typedef exists in this process.
      # '#register_query' accepts query, but force to wait actual resigtration after first data.
      @waiting_queries = {} # target => [query]
    end

    def start
      @runtime = @service.getEPRuntime
    end

    def stop
      #TODO: stop to @runtime
    end

    #TODO: API to add target (and its basic typedef)
    #TODO: API to add typedef

    def register(query) # success or not
      return false if @queries.map(&:name).include?(query.name)

      # query.name, query.expression and parsed .target & .fields
      @mutex.synchronize do
        return false if @queries.map(&:name).include?(query.name)

        @queries.push(query)

        if @targets.include?(query.target) && (!@waiting_queries.has_key?(query.target))
          # data of specified target has already arrived, and processed (by any other queries)
          register_query_actual(query)
          return true
        end

        # no one data has arrived for specified target.
        # first access for this target (of course, no one data exists)
        @targets.push(query.target) unless @targets.include?(query.target)

        @waiting_queries[query.target] ||= []
        @waiting_queries[query.target].push(query)
      end
      true
    end

    def send(target, events)
      return unless @targets.include?(target) # discard data for target not registered

      events.each do |event|
        typedef = @typedef_manager.refer(target, event)
        unless (@typedefs[target] || {}).has_key?(typedef.name)
          register_type(target, typedef)
        end

        if @waiting_queries[target]
          register_waiting_queries(target)
        end

        @runtime.sendEvent(typedef.format(event).to_java, target)
      end
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

    def register_waiting_queries(target)
      queries = @mutex.synchronize do
        @waiting_queries.delete(target) || []
      end
      queries.each do |query|
        register_query_actual(query)
      end
    end

    def register_query_actual(query)
      epl = @service.getEPAdministrator.createEPL(query.expression)
      epl.java_send :addListener, [com.espertech.esper.client.UpdateListener.java_class], Listener.new(query.name, @output_pool)
    end

    def register_type(target, typedef)
      unless @target.include?(target)
        @mutex.synchronize do
          next if @targets.include?(target)
          @targets.push(target)
        end
      end

      unless @typedefs[target]
        @mutex.synchronize do
          next if @typedefs[target]
          @typedefs[target] = {}
          @config.addEventType(target, typedef.definition.dup)
        end
      end

      unless @typedefs[target][typedef.name]
        @mutex.synchronize do
          next if @typedefs[target][typedef.name]
          @typedefs[target][typedef.name] = typedef.definition
          # Map Supertype (target) and Subtype (typedef name, like TARGET_TypeDefName)
          # http://esper.codehaus.org/esper-4.9.0/doc/reference/en-US/html/event_representation.html#eventrep-map-supertype
          # epService.getEPAdministrator().getConfiguration()
          #   .addEventType("AccountUpdate", accountUpdateDef, new String[] {"BaseUpdate"});
          @config.addEventType(typedef.name, typedef.definition.dup, [target].to_java(:string))
        end
      end
    end
  end
end
