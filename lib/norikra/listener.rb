require 'java'
require 'esper-5.2.0.jar'
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
    def self.parse(group_name)
      if group_name && group_name =~ /^([_A-Z]+)\((.*)\)$/
        {name: $1, argument: $2}
      else
        nil
      end
    end

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
      listeners = []
      self.constants.each do |c|
        next if known_consts.include?(c)

        klass = Norikra::Listener.const_get(c)
        if klass.is_a?(Class) && klass.superclass == Norikra::Listener::Base
          listeners.push(klass)
        end
      end
      [Norikra::Listener::Stdout, Norikra::Listener::Loopback].each do |listener|
        listeners.push(listener)
      end
      listeners
    end

    class Base
      include com.espertech.esper.client.UpdateListener

      DEFAULT_ASYNC_INTERVAL = 0.1

      attr_writer :events_statistics
      # attr_writer :engine
      # attr_writer :output_pool

      def self.label
        raise NotImplementedError
      end

      def initialize(argument, query_name, query_group)
        @argument = argument
        @query_name = query_name
        @query_group = query_group

        @async_interval = DEFAULT_ASYNC_INTERVAL

        @mode = if self.respond_to?(:process_sync)
                  :sync
                elsif self.respond_to?(:process_async)
                  :async
                else
                  raise "BUG: Invalid custom listener '#{self.class.to_s}'"
                end

        @thread = nil
        @events = []
        @mutex = Mutex.new
        @running = true
      end

      def start
        if @mode == :async
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
          @events += events
        end
      end

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

      def apply_type_convert_to_events(events)
        if events.respond_to?(:map)
          events.map{|e| type_convert(e) }
        else
          type_convert(events)
        end
      end

      def update(new_events, old_events)
        t = Time.now.to_i
        if @mode == :sync
          news = apply_type_convert_to_events(new_events)
          olds = apply_type_convert_to_events(old_events)
          trace("produced events"){ { listener: self.class, query: @query_name, group: @query_group, news: news, olds: olds } }
          process_sync(news, olds)
          if news.respond_to?(:size)
            @events_statistics[:output] += news.size
          end
        else # async
          events = new_events.map{|e| [t, type_convert(e)]}
          trace("pushed events"){ { listener: self.class, query: @query_name, group: @query_group, event: events } }
          push(events)
          @events_statistics[:output] += events.size
        end
      end
    end

    class MemoryPool < Base
      attr_writer :output_pool

      def self.label
        nil # Memory pool listener is built-in and implicit listener
      end

      def process_sync(news, olds)
        t = Time.now.to_i
        if news.respond_to?(:map)
          events = news.map{|e| [t, e]}
          @output_pool.push(@query_name, @query_group, events)
        end
      end
    end

    class Loopback < Base
      attr_writer :engine

      def self.label
        "LOOPBACK"
      end

      def self.target(query_group)
        if query_group
          opts = Norikra::Listener.parse(query_group)
          if opts && opts[:name] == label()
            opts[:argument]
          else
            nil
          end
        else
          nil
        end
      end

      def initialize(argument, query_name, query_group)
        super
        if @argument.nil? || @argument.empty?
          raise Norikra::ClientError, "LOOPBACK target name not specified"
        end
      end

      def process_sync(news, olds)
        # We does NOT convert 'container.$0' into container['field'].
        # Use escaped names like 'container__0'. That is NOT so confused.
        trace("loopback event"){ { query: @query_name, group: @query_group, event: news } }
        if news.respond_to?(:each)
          @engine.send(@argument, news)
        end
      end
    end

    class Stdout < Base
      attr_accessor :stdout

      def self.label
        "STDOUT"
      end

      def initialize(argument, query_name, query_group)
        super
        @stdout = STDOUT
      end

      def process_sync(news, olds)
        if news.respond_to?(:each)
          news.each do |e|
            @stdout.puts @query_name + "\t" + JSON.dump(e)
          end
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
