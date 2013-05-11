require 'norikra/engine'

require 'norikra/typedef_manager'
require 'norikra/output_pool'
require 'norikra/typedef'
require 'norikra/query'

# require 'norikra/rpc/http'
# require 'norikra/rpc/msgpack'

module Norikra
  class Server
    def initialize
      @type_manager = Norikra::TypeManager.new
      @output_pool = Norikra::OutputPool.new
      @engine = Norikra::Engine.new

      # instanciate Norikra::RPC::HTTP and Norikra::RPC::MessagePack and its threads
      @rpcserver = Norikra::RPC::HTTP.new(:engine => @engine, :port => xxx)
    end
  end
end
