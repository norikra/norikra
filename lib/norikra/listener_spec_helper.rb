module Norikra
  module ListenerSpecHelper

    ### TODO: more util methods?
    # utilities w/ #start, #shutdown ?
    # utilities to produce dummy output events ?

    class DummyEngine
      attr_reader :events

      def initialize
        @events = {}
      end

      def send(target, events)
        @events[target] ||= []
        @events[target].push(*events)
      end
    end

    class DummyOutputPool
      attr_reader :pool

      def initialize
        @pool = {}
      end

      def push(query_name, query_group, events)
        @pool[query_group] ||= {}
        @pool[query_group][query_name] ||= []
        @pool[query_group][query_name].push(*events)
      end
    end
  end
end
