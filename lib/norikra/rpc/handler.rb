require 'norikra/logger'
include Norikra::Log

class Norikra::RPC::Handler
  def initialize(engine)
    @engine = engine
  end

  def logging(type, handler, *args)
    if type == :manage
      debug "RPC", :handler => handler.to_s, :args => args
    else
      trace "RPC", :handler => handler.to_s, :args => args
    end

    begin
      yield
    rescue => e
      error "Exception #{e.class}: #{e.message}"
      e.backtrace.each do |t|
        error "  " + t
      end
      nil
    end
  end

  def targets
    logging(:show, :targets){
      @engine.targets
    }
  end

  def open(target, fields)
    logging(:manage, :open, target, fields){
      r = @engine.open(target, fields)
      !!r
    }
  end

  def close(target)
    logging(:manage, :close, target){
      r = @engine.close(target)
      !!r
    }
  end

  def queries
    logging(:show, :queries){
      @engine.queries.map(&:to_hash)
    }
  end

  def register(query_name, expression)
    logging(:manage, :register, query_name, expression){
      r = @engine.register(Norikra::Query.new(:name => query_name, :expression => expression))
      !!r
    }
  end

  def deregister(query_name)
    logging(:manage, :deregister, query_name){
      r = @engine.deregister(query_name)
      !!r
    }
  end

  def fields(target)
    logging(:show, :fields, target){
      @engine.typedef_manager.field_list(target)
    }
  end

  def reserve(target, fieldname, type)
    logging(:manage, :reserve, target, fieldname, type){
      r = @engine.reserve(target, fieldname, type)
      !!r
    }
  end

  def send(target, events)
    logging(:data, :send, target, events){
      r = @engine.send(target, events)
      !!r
    }
  end

  def event(query_name)
    logging(:show, :event, query_name){
      @engine.output_pool.pop(query_name)
    }
  end

  def sweep
    logging(:show, :sweep){
      @engine.output_pool.sweep
    }
  end

  # post('/listen') # get all events as stream, during connection keepaliving
end
