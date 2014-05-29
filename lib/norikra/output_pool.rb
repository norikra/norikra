require 'set'

module Norikra
  class OutputPool
    attr_accessor :pool

    def initialize
      @pool = {} # { query_name => [events] }
      @groups = {} # { group_name => Set(query_names) }
      @mutex = Mutex.new
    end

    def queries
      @pool.keys
    end

    def remove(query_name, query_group)
      @mutex.synchronize do
        group = @groups[query_group]
        if group
          group.delete(query_name)
        end
        @groups.delete(query_name)
      @pool.delete(query_name)
      end
      nil
    end

    def push(query_name, query_group, events) # events must be [time(int), event_record]
      # called with blank events for window leavings (and/or other situations)
      return if events.size < 1

      @mutex.synchronize do
        if @groups[query_group]
          @groups[query_group].add(query_name) # Set is unique set of elements
        else
          @groups[query_group] ||= Set.new([query_name])
        end

        @pool[query_name] ||= []
        @pool[query_name].push(events)
      end
    end

    # returns [[time, event], ...], but not remove from pool
    def fetch(query_name)
      events = @mutex.synchronize do
        @pool.fetch(query_name, [])
      end
      events.reduce(&:+) || []
    end

    # returns [[time(int from epoch), event], ...], event: hash
    def pop(query_name)
      events = @mutex.synchronize do
        @pool.delete(query_name) || []
      end
      events.reduce(&:+) || []
    end

    # returns {query_name => [[time, event], ...]}
    def sweep(group=nil)
      return {} if @groups[group].nil?

      ret = {}
      sweep_pool = @mutex.synchronize do
        sweeped = {}
        @groups[group].each do |qname|
          sweeped[qname] = @pool.delete(qname) if @pool[qname] && @pool[qname].size > 0
        end
        sweeped
      end
      sweep_pool.keys.each do |k|
        ret[k] = sweep_pool[k].reduce(&:+) || []
      end
      ret
    end
  end
end
