require 'norikra/engine'

require 'norikra/logger'
include Norikra::Log

require 'norikra/typedef_manager'
require 'norikra/output_pool'
require 'norikra/typedef'
require 'norikra/query'

require 'norikra/rpc'

module Norikra
  class Server
    RPC_DEFAULT_HOST = '0.0.0.0'
    RPC_DEFAULT_PORT = 26571
    # 26571 = 3026 + 3014 + 2968 + 2950 + 2891 + 2896 + 2975 + 2979 + 2872

    attr_accessor :running

    def initialize(host=RPC_DEFAULT_HOST, port=RPC_DEFAULT_PORT, conf={})
      #TODO: initial configuration (targets/queries)
      @typedef_manager = Norikra::TypedefManager.new
      @output_pool = Norikra::OutputPool.new

      Norikra::Log.init(conf[:loglevel], conf[:logdir], {:filesize => conf[:logfilesize], :backups => conf[:logbackups]})

      @engine = Norikra::Engine.new(@output_pool, @typedef_manager)
      @rpcserver = Norikra::RPC::HTTP.new(:engine => @engine, :port => port)
    end

    def run
      @engine.start
      @rpcserver.start
      info "Norikra server started."
      @running = true

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

    def shutdown
      info "Norikra server shutting down."
      @rpcserver.stop
      @engine.stop
      info "Norikra server shutdown complete."
    end
  end
end
