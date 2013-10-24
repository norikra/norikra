require 'norikra/engine'

require 'norikra/stats'
require 'norikra/logger'
include Norikra::Log

require 'norikra/typedef_manager'
require 'norikra/output_pool'
require 'norikra/typedef'
require 'norikra/query'

require 'norikra/rpc'
require 'norikra/webui'

require 'norikra/udf'

module Norikra
  class Server
    attr_accessor :running

    MICRO_PREDEFINED = {
      :engine => { inbound:    { threads: 0, capacity: 0 }, outbound:   { threads: 0, capacity: 0 },
                   route_exec: { threads: 0, capacity: 0 }, timer_exec: { threads: 0, capacity: 0 }, },
      :rpc => { threads: 2 },
      :web => { threads: 2 },
    }
    SMALL_PREDEFINED = {
      :engine => { inbound:    { threads: 1, capacity: 0 }, outbound:   { threads: 1, capacity: 0 },
                   route_exec: { threads: 1, capacity: 0 }, timer_exec: { threads: 1, capacity: 0 }, },
      :rpc => { threads: 2 },
      :web => { threads: 2 },
    }
    MIDDLE_PREDEFINED = {
      :engine => { inbound:    { threads: 4, capacity: 0 }, outbound:   { threads: 2, capacity: 0 },
                   route_exec: { threads: 2, capacity: 0 }, timer_exec: { threads: 2, capacity: 0 }, },
      :rpc => { threads: 4 },
      :web => { threads: 2 },
    }
    LARGE_PREDEFINED = {
      :engine => { inbound:    { threads: 6, capacity: 0 }, outbound:   { threads: 6, capacity: 0 },
                   route_exec: { threads: 4, capacity: 0 }, timer_exec: { threads: 4, capacity: 0 }, },
      :rpc => { threads: 8 },
      :web => { threads: 2 },
    }

    def self.threading_configuration(conf, stats)
      threads = case conf[:predefined]
                when :micro then MICRO_PREDEFINED
                when :small then SMALL_PREDEFINED
                when :middle then MIDDLE_PREDEFINED
                when :large then LARGE_PREDEFINED
                else (stats ? stats.threads : MICRO_PREDEFINED)
                end
      [:inbound, :outbound, :route_exec, :timer_exec].each do |type|
        [:threads, :capacity].each do |item|
          threads[:engine][type][item] = conf[:engine][type][item] if conf[:engine][type][item]
        end
      end
      threads[:rpc][:threads] = conf[:rpc][:threads] if conf[:rpc][:threads]
      threads[:web][:threads] = conf[:web][:threads] if conf[:web][:threads]
      threads
    end

    def self.log_configuration(conf, stats)
      logconf = stats ? stats.log : { level: nil, dir: nil, filesize: nil, backups: nil }
      [:level, :dir, :filesize, :backups].each do |sym|
        logconf[sym] = conf[sym] if conf[sym]
      end
      logconf
    end

    def initialize(host, port, conf={})
      if conf[:daemonize]
        outfile_path = conf[:daemonize][:outfile] || File.join(conf[:log][:dir], 'norikra.out')
        Dir.chdir("/")
        STDIN.reopen("/dev/null")
        outfile = File.open(outfile_path, 'w')
        STDOUT.reopen(outfile)
        STDERR.reopen(outfile)
        puts "working on #{$PID}"
      end

      @stats_path = conf[:stats][:path]
      @stats_suppress_dump = conf[:stats][:suppress]
      @stats = if @stats_path && test(?r, @stats_path)
                 Norikra::Stats.load(@stats_path)
               else
                 nil
               end

      @host = host || (@stats ? @stats.host : nil)
      @port = port || (@stats ? @stats.port : nil)
      @ui_port = @stats ? @stats.ui_port : nil

      @thread_conf = self.class.threading_configuration(conf[:thread], @stats)
      @log_conf = self.class.log_configuration(conf[:log], @stats)

      Norikra::Log.init(@log_conf[:level], @log_conf[:dir], {:filesize => @log_conf[:filesize], :backups => @log_conf[:backups]})

      info "thread configurations", @thread_conf
      info "logging configurations", @log_conf

      @typedef_manager = Norikra::TypedefManager.new
      @output_pool = Norikra::OutputPool.new

      @engine = Norikra::Engine.new(@output_pool, @typedef_manager, {thread: @thread_conf[:engine]})

      @rpcserver = Norikra::RPC::HTTP.new(
        :engine => @engine,
        :host => @host, :port => @port,
        :threads => @thread_conf[:rpc][:threads]
      )
      @webserver = Norikra::WebUI::HTTP.new(
        :engine => @engine,
        :host => @host, :port => @ui_port,
        :threads => @thread_conf[:web][:threads]
      )
    end

    def run
      @engine.start

      load_plugins

      if @stats
        info "loading from stats file"
        if @stats.targets && @stats.targets.size > 0
          @stats.targets.each do |target|
            @engine.open(target[:name], target[:fields], target[:auto_field])
          end
        end
        if @stats.queries && @stats.queries.size > 0
          @stats.queries.each do |query|
            @engine.register(Norikra::Query.new(:name => query[:name], :expression => query[:expression]))
          end
        end
      end

      @rpcserver.start
      @webserver.start

      @running = true
      info "Norikra server started."

      shutdown_proc = ->{ @running = false }
      # JVM uses SIGQUIT for thread/heap state dumping
      [:INT, :TERM].each do |s|
        Signal.trap(s, shutdown_proc)
      end
      #TODO: SIGHUP? SIGUSR1? SIGUSR2? (dumps of query/fields? or other handler?)

      while @running
        sleep 0.3
      end
    end

    def load_plugins
      info "Loading UDF plugins"
      Norikra::UDF.listup.each do |mojule|
        if mojule.is_a?(Class)
          name = @engine.load(mojule)
          info "UDF loaded", :name => name
        elsif mojule.is_a?(Module) && mojule.respond_to?(:plugins)
          mojule.init if mojule.respond_to?(:init)
          mojule.plugins.each do |klass|
            name = @engine.load(klass)
            info "UDF loaded", :name => name
          end
        end
      end
    end

    def shutdown
      info "Norikra server shutting down."
      @webserver.stop
      @rpcserver.stop
      @engine.stop
      info "Norikra server stopped."

      if @stats_path && !@stats_suppress_dump
        stats = Norikra::Stats.new(
          host: @host,
          port: @port,
          threads: @thread_conf,
          log: @log_conf,
          targets: @engine.targets.map{|t|
            {
              :name => t.name,
              :fields => @engine.typedef_manager.dump_target(t.name),
              :auto_field => t.auto_field
            }
          },
          queries: @engine.queries.map{|q| {:name => q.name, :expression => q.expression}}
        )
        stats.dump(@stats_path)
        info "Current status saved", :path => @stats_path
      end

      info "Norikra server shutdown complete."
    end
  end
end
