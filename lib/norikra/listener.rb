require 'java'
require 'esper-5.0.0.jar'
require 'esper/lib/commons-logging-1.1.3.jar'
require 'esper/lib/antlr-runtime-4.1.jar'
require 'esper/lib/cglib-nodep-3.1.jar'

require 'rubygems'

require 'norikra/field'
require 'norikra/query'

require 'norikra/logger'
include Norikra::Log

require 'json'

module Norikra
  module Listener
    def self.listup
      return unless defined? Gem

      plugins = Gem.find_latest_files('norikra/listener/*.rb')
      plugins.each do |plugin|
        begin
          debug "plugin file found!", file: plugin
          rbpath = plugin.dup
          4.times do
            rbpath = File.dirname( rbpath )
          end
          files = Dir.entries( rbpath )
          gemname = files.select{|f| f=~ /\.gemspec$/ }.first.sub(/\.gemspec$/, '')
          trace "Loading listener gem", gemname: gemname, path: plugin
          require gemname
          load plugin
        rescue => e
          warn "Failed to load norikra listener plugin", plugin: plugin.to_s, error_class: e.class, error: e.message
          e.backtrace.each do |t|
            warn "  " + t
          end
        end
      end

      known_consts = [:Base, :MemoryPool, :Loopback, :Stdout]
      listeners = [Norikra::Listener::Stdout, Norikra::Listener::Loopback]
      self.constants.each do |c|
        next if known_consts.include?(c)

        klass = Norikra::Listener.const_get(c)
        if klass.is_a?(Class) && klass.superclass == Norikra::Listener::Base
          listeners.push(klass)
        end
      end
      listeners.push(Norikra::Listener::MemoryPool)
      listeners
    end

    class Base
      include com.espertech.esper.client.UpdateListener

      DEFAULT_ASYNC_INTERVAL = 0.1

      def self.check(group_name)
        raise NotImplementedError
      end

      def initialize(query_name, query_group, events_statistics)
        @query_name = query_name
        @query_group = query_group
        @events_statistics = events_statistics

        @async_interval = DEFAULT_ASYNC_INTERVAL

        @thread = nil
        @events = []
        @mutex = Mutex.new
        @running = true
      end

      # def engine=(engine)
      #   @engine = engine
      # end

      # def output_pool=(output_pool)
      #   @output_pool = output_pool
      # end

      def start
        if self.respond_to?(:process_async)
          trace "starting thread to process events in background", query: @query_name
          @thread = Thread.new(&method(:background))
        end
      end

      def background
        trace "backgroupd thread starts", query: @query_name
        while @running
          events_empty = true
          events = nil
          @mutex.synchronize do
            events = @events
            @events = []
          end
          unless events.empty?
            events_empty = false
            trace("calling #process_async"){ {listener: self.class, query: @query_name, events: events.size} }
            process_async(events)
          end
          sleep @async_interval if events_empty
        end
      rescue => e
        error "exception in listener background thread, stopped", listener: self.class, query: @query_name, error: e
      end

      def push(events)
        @mutex.synchronize do
          @events << events
        end
      end

      # def process_async
      # end

      def shutdown
        trace "stopping listener", query: @query_name
        @running = false
        @thread.join if @thread
        @thread = nil
      end

      def type_convert(value)
        if value.respond_to?(:getUnderlying)
          value = value.getUnderlying
        end

        trace("converting"){ { value: value } }

        if value.nil?
          value
        elsif value.respond_to?(:to_hash)
          Hash[ value.to_hash.map{|k,v| [ Norikra::Field.unescape_name(k), type_convert(v)] } ]
        elsif value.respond_to?(:to_a)
          value.to_a.map{|v| type_convert(v) }
        elsif value.respond_to?(:force_encoding)
          value.force_encoding('UTF-8')
        else
          value
        end
      end

      def update(new_events, old_events)
        t = Time.now.to_i
        events = new_events.map{|e| [t, type_convert(e)]}
        trace("updated event"){ { query: @query_name, group: @query_group, event: events } }
        push(events)
        @events_statistics[:output] += events.size
      end
    end

    class MemoryPool < Base
      def self.check(group_name)
        true
      end

      def output_pool=(output_pool)
        @output_pool = output_pool
      end

      def update(new_events, old_events)
        t = Time.now.to_i
        events = new_events.map{|e| [t, type_convert(e)]}
        trace("updated event"){ { query: @query_name, group: @query_group, event: events } }
        @output_pool.push(@query_name, @query_group, events)
        @events_statistics[:output] += events.size
      end
    end

    class Loopback < Base
      def self.check(group_name)
        group_name && group_name =~ /^LOOPBACK\((.+)\)$/ && $1
      end

      def initialize(query_name, query_group, events_statistics)
        super
        @loopback_target = Loopback.check(query_group)
        raise "BUG: query group is not 'LOOPBACK(...)'" unless @loopback_target
      end

      def engine=(engine)
        @engine = engine
      end

      def update(new_events, old_events)
        event_list = new_events.map{|e| type_convert(e) }
        trace("loopback event"){ { query: @query_name, group: @query_group, event: event_list } }
        @events_statistics[:output] += event_list.size
        #
        # We does NOT convert 'container.$0' into container['field'].
        # Use escaped names like 'container__0'. That is NOT so confused.
        @engine.send(@loopback_target, event_list)
      end
    end

    class Stdout < Base
      def self.check(group_name)
        group_name && group_name == "STDOUT()"
      end

      def initialize(query_name, query_group, events_statistics)
        super
        raise "BUG: query group is not 'STDOUT()'" unless Stdout.check(query_group)
        @stdout = STDOUT
      end

      def update(new_events, old_events)
        event_list = new_events.map{|e| type_convert(e) }
        trace("stdout event"){ { query: @query_name, event: event_list } }
        @events_statistics[:output] += event_list.size

        event_list.each do |e|
          @stdout.puts @query_name + "\t" + JSON.dump(e)
        end
      end
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
