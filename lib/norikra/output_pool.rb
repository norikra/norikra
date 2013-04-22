module Norikra
  class OutputPool
    attr_accessor :pool

    def initialize
      @pool = {}
      @mutex = Mutex.new
    end

    def push(tablename, events)
      t = Time.now.to_i
      if events.first.respond_to?(:getUnderlying) # easy to test...
        events = events.map{|e| [t, e.getUnderlying]}
      else
        events = events.map{|e| [t, e]}
      end
      @mutex.synchronize do
        @pool[tablename] ||= []
        @pool[tablename] += events
      end
    end

    # returns [time(int from epoch), event], event: hash
    def pop(tablename)
      @mutex.synchronize do
        @pool.delete(tablename) || []
      end
    end
  end
end
