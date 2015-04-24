require 'mizuno/server'
require 'rack/builder'

require_relative 'handler'
require_relative 'api'

require 'norikra/logger'
include Norikra::Log

module Norikra::WebUI
  class HTTP
    DEFAULT_LISTEN_HOST = '0.0.0.0'
    DEFAULT_LISTEN_PORT = 26578
    # 26578 from 26571 and magic number 8 (for web)

    DEFAULT_THREADS = 2

    attr_accessor :host, :port, :threads
    attr_accessor :engine, :mizuno, :thread

    def initialize(opts={})
      @engine = opts[:engine]
      @host = opts[:host] || DEFAULT_LISTEN_HOST
      @port = opts[:port] || DEFAULT_LISTEN_PORT
      @threads = opts[:threads] || DEFAULT_THREADS
      Norikra::WebUI::Handler.engine = @engine
      Norikra::WebUI::API.engine = @engine
      @app = Rack::Builder.new {
        map opts[:context_path] do
          map '/api' do
            run Norikra::WebUI::API
          end
          run Norikra::WebUI::Handler
        end
      }
    end

    def start
      info "WebUI server #{@host}:#{@port}, #{@threads} threads"
      @thread = Thread.new do
        @mizuno = Mizuno::Server.new
        @mizuno.run(@app, embedded: true, threads: @threads, min_threads: @threads, port: @port, host: @host)
      end
    end

    def stop
      @mizuno.stop
      @thread.kill
      @thread.join
    end

    def shut_off(mode)
      Norikra::WebUI::Handler.shut_off = mode
      Norikra::WebUI::API.shut_off = mode
    end
  end
end
