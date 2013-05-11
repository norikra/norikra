require 'mizuno/server'
require 'rack/builder'
require 'norikra/rpc/handler'

module Norikra::RPC
  class HTTP
    #TODO Xmx of mizuno/jetty
    attr_accessor :host, :port, :threads
    attr_accessor :engine, :mizuno, :thread

    def initialize(opts={})
      @engine = opts[:engine]
      @port = opts[:port]
      @app = Rack::Builder.new {
        run Norikra::RPC::Handler
      }
    end

    def start
      @thread = Thread.new do
        @mizuno = Mizuno::Server.new
        @mizuno.run(@app, :embedded => true, :threads => 5, :port => 8080, :host => nil)
      end
    end

    def stop
      @mizuno.stop
      @thread.kill
      @thread.join
    end
  end
end
