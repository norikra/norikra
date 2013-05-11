require 'norikra/engine'

require 'norikra/typedef_manager'
require 'norikra/output_pool'
require 'norikra/typedef'
require 'norikra/query'

require 'norikra/rpc'

module Norikra
  class Server
    def initialize
      @typedef_manager = Norikra::TypedefManager.new
      @output_pool = Norikra::OutputPool.new
      @engine = Norikra::Engine.new(@output_pool, @typedef_manager)
      @rpcserver = Norikra::RPC::HTTP.new(:engine => @engine, :port => xxx)
    end

    def run
      @engine.start
      @rpcserver.start
    end

    def shutdown
      #TODO: stop order
      @rpcserver.stop
      @engine.stop
    end
  end
end
