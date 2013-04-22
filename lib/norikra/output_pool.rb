module Norikra
  class OutputPool
    def initialize
      @pool = {}
      @mutex = Mutex.new
    end

    def push(tablename, events)
      events = events.map(&:getUnderlying)
      @mutex.synchronize do
        @pool[tablename] ||= []
        @pool[tablename] += events
      end
    end

    def pop(tablename)
      @mutex.synchronize do
        @pool.delete(tablename) || []
      end
    end
  end
end
