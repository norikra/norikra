require 'mizuno/server'
require 'rack/builder'
require 'msgpack-rpc-over-http-jruby'

require_relative 'handler'

module Norikra::RPC
  class HTTP
    DEFAULT_THREADS = 2

    attr_accessor :host, :port, :threads
    attr_accessor :engine, :mizuno, :thread

    def initialize(opts={})
      @engine = opts[:engine]
      @host = opts[:host]
      @port = opts[:port]
      @threads = opts[:threads] || DEFAULT_THREADS
      handler = Norikra::RPC::Handler.new(@engine)
      @app = Rack::Builder.new {
        run MessagePack::RPCOverHTTP::Server.app(handler)
      }
    end

    def start
      @thread = Thread.new do
        @mizuno = Mizuno::Server.new
        @mizuno.run(@app, :embedded => true, :threads => @threads, :port => @port, :host => @host)
      end
    end

    def stop
      @mizuno.stop
      @thread.kill
      @thread.join
    end
  end
end
