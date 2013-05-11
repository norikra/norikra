require 'pp'
require 'rack/builder'
require 'mizuno/server'

app = Rack::Builder.new {
  map "/" do
    run lambda {|env| [200, {'Content-Type' => 'text/plain'}, ['Testing for Glassfish']] }
  end
}

pp 'starting server....'
mizuno = nil
server = Thread.new do
  mizuno = Mizuno::Server.new
  mizuno.run(app, :embedded => true, :threads => 5, :port => 8080, :host => nil)
end
pp 'success to start mizuno/server'

require 'net/http'

res = Net::HTTP.get('localhost', '/', 8080)
pp res

pp 'ending'
mizuno.stop
server.kill
server.join
pp 'end.'
