require 'msgpack-rpc-over-http-jruby'

module Norikra::RPC
  class ClientError < MessagePack::RPCOverHTTP::RemoteError; end
  class ServerError < MessagePack::RPCOverHTTP::RemoteError; end
  class ServiceUnavailableError < MessagePack::RPCOverHTTP::RemoteError; end
end

require 'norikra/rpc/handler'
require 'norikra/rpc/http'
