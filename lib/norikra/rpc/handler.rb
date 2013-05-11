require 'sinatra/base'
require 'json'
require 'msgpack'

class Norikra::RPC::Handler < Sinatra::Base
  get('/') do
    "OK"
  end

  # get('/tables')
  # get('/queries')

  # post('/add/typedef') #TODO: typedef ? field with type ?
  # post('/add/query')

  # post('/send/json/:query_name') # send events by json
  # post('/send/msgpack/:query_name') # send events by msgpack

  # post('/event/:query_name') # get event for query
  # post('/sweep')  # get all events
  # post('/listen') # get all events as stream, during connection keepaliving
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
