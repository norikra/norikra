require 'norikra/logger'
include Norikra::Log

require 'norikra/rpc'

class Norikra::RPC::Gatekeeper
  # handler of "GET /" to respond for monitor tools
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["REQUEST_METHOD"] == 'GET' && env["PATH_INFO"] == '/'
      return [ 200, {'Content-Type' => 'text/plain'}, ['Norikra alive!'] ]
    end
    return @app.call(env)
  end
end
