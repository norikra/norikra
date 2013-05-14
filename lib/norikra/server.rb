require 'norikra/engine'

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

    def initialize(host=RPC_DEFAULT_HOST, port=RPC_DEFAULT_PORT, configuration={})
      #TODO: initial configuration
      @typedef_manager = Norikra::TypedefManager.new

      @output_pool = Norikra::OutputPool.new

      @engine = Norikra::Engine.new(@output_pool, @typedef_manager)
      @rpcserver = Norikra::RPC::HTTP.new(:engine => @engine, :port => port)
    end

    def run
      @engine.start
      @rpcserver.start
      p "Norikra server started."
      #TODO: main loop and signal traps
      #TODO: loggings
      sleep 50
    end

    def shutdown
      #TODO: stop order
      @rpcserver.stop
      @engine.stop
    end
  end
end
