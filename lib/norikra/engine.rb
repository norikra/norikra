require 'java'
require 'esper-4.9.0.jar'
require 'esper/lib/commons-logging-1.1.1.jar'
require 'esper/lib/antlr-runtime-3.2.jar'
require 'esper/lib/cglib-nodep-2.2.jar'

require 'norikra/typedef_manager'

####TODO: fix 'table' into 'target', and add 'stream' keyword support

module Norikra
  class Engine
    attr_reader :tables, :queries, :output_pool, :typedef_manager

    def initialize(output_pool, typedef_manager=nil)
      @output_pool = output_pool
      @typedef_manager = typedef_manager || Norikra::TypedefManager.new()

      @service = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider
      @config = @service.getEPAdministrator.getConfiguration

      @mutex = Mutex.new

      # if @typedefs[tablename] exists, first data has already arrived.
      @typedefs = {} # tablename => {typedefname => definition}

      @tables = []
      @queries = []

      # Queries must be registered with typedef, but when no data reached, no typedef exists in this process.
      # '#register_query' accepts query, but force to wait actual resigtration after first data.
      @waiting_queries = {} # tablename => [query]
    end

    def start
      @runtime = @service.getEPRuntime
    end

    def stop
      #TODO: stop to @runtime
    end

    #TODO: API to add table (and its basic typedef)
    #TODO: API to add typedef

    def register(query) # success or not
      return false if @queries.map(&:name).include?(query.name)

      # query.name, query.expression and parsed .tablename & .fields
      @mutex.synchronize do
        return false if @queries.map(&:name).include?(query.name)

        @queries.push(query)

        if @tables.include?(query.tablename) && (!@waiting_queries.has_key?(query.tablename))
          # data of specified table has already arrived, and processed (by any other queries)
          register_query_actual(query)
          return true
        end

        # no one data has arrived for specified table.
        # first access for this tablename (of course, no one data exists)
        @tables.push(query.tablename) unless @tables.include?(query.tablename)

        @waiting_queries[query.tablename] ||= []
        @waiting_queries[query.tablename].push(query)
      end
      true
    end

    def send(tablename, events)
      return unless @tables.include?(tablename) # discard data for table not registered

      events.each do |event|
        typedef = @typedef_manager.refer(tablename, event)
        unless (@typedefs[tablename] || {}).has_key?(typedef.name)
          register_type(tablename, typedef)
        end

        if @waiting_queries[tablename]
          register_waiting_queries(tablename)
        end

        @runtime.sendEvent(typedef.format(event).to_java, tablename)
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

    def register_waiting_queries(tablename)
      queries = @mutex.synchronize do
        @waiting_queries.delete(tablename) || []
      end
      queries.each do |query|
        register_query_actual(query)
      end
    end

    def register_query_actual(query)
      epl = @service.getEPAdministrator.createEPL(query.expression)
      epl.java_send :addListener, [com.espertech.esper.client.UpdateListener.java_class], Listener.new(query.name, @output_pool)
    end

    def register_type(tablename, typedef)
      unless @tables.include?(tablename)
        @mutex.synchronize do
          next if @tables.include?(tablename)
          @tables.push(tablename)
        end
      end

      unless @typedefs[tablename]
        @mutex.synchronize do
          next if @typedefs[tablename]
          @typedefs[tablename] = {}
          @config.addEventType(tablename, typedef.definition.dup)
        end
      end

      unless @typedefs[tablename][typedef.name]
        @mutex.synchronize do
          next if @typedefs[tablename][typedef.name]
          @typedefs[tablename][typedef.name] = typedef.definition
          # Map Supertype (tablename) and Subtype (typedef name, like TABLENAME_TypeDefName)
          # http://esper.codehaus.org/esper-4.9.0/doc/reference/en-US/html/event_representation.html#eventrep-map-supertype
          # epService.getEPAdministrator().getConfiguration()
          #   .addEventType("AccountUpdate", accountUpdateDef, new String[] {"BaseUpdate"});
          @config.addEventType(typedef.name, typedef.definition.dup, [tablename].to_java(:string))
        end
      end
    end
  end
end
