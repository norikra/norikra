require 'norikra/engine'

require 'norikra/logger'
include Norikra::Log

require 'norikra/typedef_manager'
require 'norikra/output_pool'
require 'norikra/typedef'
require 'norikra/query'

require 'norikra/rpc'
require 'norikra/udf'

module Norikra
  class Server
    RPC_DEFAULT_HOST = '0.0.0.0'
    RPC_DEFAULT_PORT = 26571
    # 26571 = 3026 + 3014 + 2968 + 2950 + 2891 + 2896 + 2975 + 2979 + 2872

    attr_accessor :running

    MICRO_PREDEFINED = {
      :engine => { inbound:    { threads: 0, capacity: 0 }, outbound:   { threads: 0, capacity: 0 },
                   route_exec: { threads: 0, capacity: 0 }, timer_exec: { threads: 0, capacity: 0 }, },
      :rpc => { threads: 2 },
    }
    SMALL_PREDEFINED = {
      :engine => { inbound:    { threads: 1, capacity: 0 }, outbound:   { threads: 1, capacity: 0 },
                   route_exec: { threads: 1, capacity: 0 }, timer_exec: { threads: 1, capacity: 0 }, },
      :rpc => { threads: 2 },
    }
    MIDDLE_PREDEFINED = {
      :engine => { inbound:    { threads: 4, capacity: 0 }, outbound:   { threads: 2, capacity: 0 },
                   route_exec: { threads: 2, capacity: 0 }, timer_exec: { threads: 2, capacity: 0 }, },
      :rpc => { threads: 4 },
    }
    LARGE_PREDEFINED = {
      :engine => { inbound:    { threads: 6, capacity: 0 }, outbound:   { threads: 6, capacity: 0 },
                   route_exec: { threads: 4, capacity: 0 }, timer_exec: { threads: 4, capacity: 0 }, },
      :rpc => { threads: 8 },
    }

    #TODO: basic configuration from stat file
    def self.threading_configuration(conf)
      # t_original = stat file
      # t overwrites t_original

      t = case conf[:predefined]
          when :micro then MICRO_PREDEFINED
          when :small then SMALL_PREDEFINED
          when :middle then MIDDLE_PREDEFINED
          when :large then LARGE_PREDEFINED
          else MICRO_PREDEFINED # default
          end
      [:inbound, :outbound, :route_exec, :timer_exec].each do |type|
        [:threads, :capacity].each do |item|
          t[:engine][type][item] = conf[:engine][type][item] if conf[:engine][type][item]
        end
      end
      t[:rpc][:threads] = conf[:rpc][:threads] if conf[:rpc][:threads]
      t
    end

    #TODO: basic configuration from stat file
    def self.log_configuration(conf)
      conf
    end

    def initialize(host=RPC_DEFAULT_HOST, port=RPC_DEFAULT_PORT, conf={})
      #TODO: initial configuration (targets/queries)
      @thread_conf = self.class.threading_configuration(conf[:thread])
      @log_conf = self.class.log_configuration(conf[:log])

      Norikra::Log.init(@log_conf[:level], @log_conf[:dir], {:filesize => @log_conf[:filesize], :backups => @log_conf[:backups]})

      info "thread configurations", @thread_conf
      info "logging configurations", @log_conf

      @typedef_manager = Norikra::TypedefManager.new
      @output_pool = Norikra::OutputPool.new

      @engine = Norikra::Engine.new(@output_pool, @typedef_manager, {thread: @thread_conf[:engine]})
      @rpcserver = Norikra::RPC::HTTP.new(:engine => @engine, :port => port, :threads => @thread_conf[:rpc][:threads])
    end

    def run
      @engine.start
      @rpcserver.start

      load_plugins

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
      @rpcserver.stop
      @engine.stop
      info "Norikra server shutdown complete."
    end
  end
end
