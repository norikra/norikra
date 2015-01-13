require 'norikra/error'
require 'norikra/logger'
include Norikra::Log

require 'norikra/webui'

require 'norikra/query'

require 'sinatra/base'
require 'sinatra/json'

# mounted on '/api'

class Norikra::WebUI::API < Sinatra::Base
  def logger ; Norikra::Log.logger ; end

  def self.engine=(engine)
    @@engine = engine
  end

  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
      'Access-Control-Allow-Headers' => 'Content-Type'
    if request.request_method == 'OPTIONS'
      halt 200
    end
  end

  def logging(type, handler, args=[], opts={})
    if type == :manage
      debug "WebAPI", handler: handler.to_s, args: args
    else
      trace "WebAPI", handler: handler.to_s, args: args
    end

    begin
      yield
    rescue Norikra::ClientError => e
      logger.info "WebAPI #{e.class}: #{e.message}"
      if opts[:on_error_hook]
        opts[:on_error_hook].call(e.class, e.message)
      else
        halt 400, {'Content-Type' => 'application/json'}, {error: e.class.to_s, message: e.message}.to_json
      end
    rescue => e
      logger.error "WebAPI #{e.class}: #{e.message}"
      e.backtrace.each do |t|
        logger.error "  " + t
      end
      if opts[:on_error_hook]
        opts[:on_error_hook].call(e.class, e.message)
      else
        halt 500, {'Content-Type' => 'application/json'}, {error: e.class.to_s, message: e.message}.to_json
      end
    end
  end

  def engine; @@engine; end

  def parse_args(param_names, request)
    body = request.body.read
    parsed = begin
               JSON.parse(body)
             rescue JSON::ParserError => e
               info "JSON content body parse error"
               {}
             end
    return parsed if parsed.is_a?(Array)

    param_names.map{|name| parsed[name] }
  end

  get '/targets' do
    logging(:show, :targets){
      json engine.targets.map(&:to_hash)
    }
  end

  post '/open' do
    target, fields, auto_field = args = parse_args(['target', 'fields', 'auto_field'], request)
    logging(:manage, :open, args){
      r = engine.open(target, fields, auto_field)
      json result: (!!r)
    }
  end

  post '/close' do
    target, = args = parse_args(['target'], request)
    logging(:manage, :close, args){
      r = engine.close(target)
      json result: (!!r)
    }
  end

  post '/modify' do
    target, auto_field = args = parse_args(['target', 'auto_field'], request)
    logging(:manage, :modify, args){
      r = engine.modify(target, auto_field)
      json result: (!!r)
    }
  end

  get '/queries' do
    logging(:show, :queries){
      json engine.queries.map(&:to_hash)
    }
  end

  post '/register' do
    query_name, query_group, expression = args = parse_args(['query_name', 'query_group', 'expression'], request)
    logging(:manage, :register, args){
      r = engine.register(Norikra::Query.new(name: query_name, group: query_group, expression: expression))
      json result: (!!r)
    }
  end

  post '/deregister' do
    query_name, = args = parse_args(['query_name'], request)
    logging(:manage, :deregister, args){
      r = engine.deregister(query_name)
      json result: (!!r)
    }
  end

  get '/fields' do
    target, = args = parse_args(['target'], request)
    logging(:show, :fields, args){
      json engine.typedef_manager.field_list(target)
    }
  end

  post '/reserve' do
    target, fieldname, type = args = parse_args(['target', 'fieldname', 'type'], request)
    logging(:manage, :reserve, args){
      r = engine.reserve(target, fieldname, type)
      json result: (!!r)
    }
  end

  post '/send' do
    target, events = args = parse_args(['target', 'events'], request)
    logging(:data, :send, args){
      r = engine.send(target, events)
      json result: (!!r)
    }
  end

  post '/event' do
    query_name, = args = parse_args(['query_name'], request)
    logging(:show, :event, args){
      json engine.output_pool.pop(query_name)
    }
  end

  get '/see' do
    query_name, = args = parse_args(['query_name'], request)
    logging(:show, :see, args){
      json engine.output_pool.fetch(query_name)
    }
  end

  post '/sweep' do
    query_group, = args = parse_args(['query_group'], request)
    logging(:show, :sweep){
      json engine.output_pool.sweep(query_group)
    }
  end

  get '/logs' do
    logging(:show, :logs){
      json Norikra::Log.logger.buffer
    }
  end

  # post('/listen') # get all events as stream, during connection keepaliving
end
