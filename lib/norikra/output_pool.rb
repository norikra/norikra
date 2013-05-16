module Norikra
  class OutputPool
    attr_accessor :pool

    def initialize
      @pool = {}
      @mutex = Mutex.new
    end

    def queries
      @pool.keys
    end

    def push(query_name, events)
      t = Time.now.to_i
      events = events.map{|e| [t, (e.respond_to?(:getUnderlying) ? e.getUnderlying : e).to_hash]}
      @mutex.synchronize do
        @pool[query_name] ||= []
        @pool[query_name].push(events) if events.size > 0
      end
    end

    # returns [[time(int from epoch), event], ...], event: hash
    def pop(query_name)
      events = @mutex.synchronize do
        @pool.delete(query_name) || []
      end
      events.reduce(&:+) || []
    end

    # returns {query_name => [[time, event], ...]}
    def sweep
      ret = {}
      sweep_pool = @mutex.synchronize do
        sweeped = @pool
        @pool = {}
        sweeped
      end
      sweep_pool.keys.each do |k|
        ret[k] = sweep_pool[k].reduce(&:+) || []
      end
      ret
    end
  end
end
