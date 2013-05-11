require 'sinatra/base'

class Norikra::RPC::Handler < Sinatra::Base
  get '/' do
    "OK"
  end
end

# get '/foo' do
#   status 418
#   headers \
#     "Allow"   => "BREW, POST, GET, PROPFIND, WHEN",
#     "Refresh" => "Refresh: 20; http://www.ietf.org/rfc/rfc2324.txt"
#   body "I'm a tea pot!"
# end

# get '/' do
#   stream do |out|
#     out << "It's gonna be legen -\n"
#     sleep 0.5
#     out << " (wait for it) \n"
#     sleep 1
#     out << "- dary!\n"
#   end
# end
