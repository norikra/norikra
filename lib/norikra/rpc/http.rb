require 'mizuno/server'
require 'rack/builder'
require 'msgpack-rpc-over-http-jruby'

require_relative 'handler'

module Norikra::RPC
  class HTTP
    #TODO Xmx of mizuno/jetty
    attr_accessor :host, :port, :threads
    attr_accessor :engine, :mizuno, :thread

    def initialize(opts={})
      @engine = opts[:engine]
      @host = opts[:host]
      @port = opts[:port]
      handler = Norikra::RPC::Handler.new(@engine)
      @app = Rack::Builder.new {
        run MessagePack::RPCOverHTTP::Server.app(handler)
      }
    end

    def start
      @thread = Thread.new do
        @mizuno = Mizuno::Server.new
        @mizuno.run(@app, :embedded => true, :threads => 5, :port => @port, :host => @host)
      end
    end

    def stop
      @mizuno.stop
      @thread.kill
      @thread.join
    end
  end
end
