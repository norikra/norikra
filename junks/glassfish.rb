# glassfish.gem is not maintained now...

require 'pp'
require 'rubygems'
require 'rdoc/usage'
require 'glassfish'

server = nil
thread = Thread.new do
  server = Glassfish::Server.new(:port => 8080) do
    lambda {|env| [200, {'Content-Type' => 'text/plain'}, 'Testing for Glassfish']}
  end
  server.start
end

#server.stop

