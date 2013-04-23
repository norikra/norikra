require 'java'
require 'esper-4.9.0.jar'
require 'esper/lib/commons-logging-1.1.1.jar'
require 'esper/lib/antlr-runtime-3.2.jar'
require 'esper/lib/cglib-nodep-2.2.jar'

module Norikra
  class Engine
    def initialize(output_pool)
      @output_pool = output_pool

      @service = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider
      @config = @service.getEPAdministrator.getConfiguration

      @tables = []
      @typedefs = {}

      @runtime = @service.getEPRuntime
    end

    def register(query)
      # query.tablename, query.typedef, query.expression
      register_type(query.tablename, query.typedef)
      # epl = @service.getEPAdministrator.createEPL(query.expression)
      # epl.java_send :addListener, [com.espertech.esper.client.UpdateListener], Listener.new(query.tablename, @output_pool)
      @service.getEPAdministrator.createEPL(query.expression).addListener(Listener.new(query.name, @output_pool))
    end

    def register_type(tablename, typedef)
      @tables.push(tablename) unless @tables.include?(tablename)

      unless @typedefs[tablename]
        @typedefs[tablename] ||= {}
        @config.addEventType(tablename, typedef.definition)
      end

      unless @typedefs[tablename][typedef.name]
        @typedefs[tablename][typedef.name] = typedef.definition
        # Map Supertype (tablename) and Subtype (typedef name, like TABLENAME_TypeDefName)
        # http://esper.codehaus.org/esper-4.9.0/doc/reference/en-US/html/event_representation.html#eventrep-map-supertype
        # epService.getEPAdministrator().getConfiguration()
        #   .addEventType("AccountUpdate", accountUpdateDef, new String[] {"BaseUpdate"});
        @config.addEventType(typedef.name, typedef.definition, [tablename].to_java(:string))
      end
    end

    def send(tablename, events)
      return unless @tables.include?(tablename)
      events.each{|e| @runtime.sendEvent(e.to_java, tablename)}
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
  end
end
