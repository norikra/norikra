class Norikra::RPC::Handler
  def initialize(engine)
    @engine = engine
  end

  def targets
    @engine.targets
  end

  def open(target, fields)
    r = @engine.open(target, fields)
    !!r
  end

  def close(target)
    r = @engine.close(target)
    !!r
  end

  def queries
    @engine.queries.map(&:to_hash)
  end

  def register(query_name, expression)
    r = @engine.register(Norikra::Query.new(:name => query_name, :expression => expression))
    !!r
  end

  def deregister(query_name)
    #TODO: write!
    raise NotImplementedError
  end

  def fields(target)
    @engine.typedef_manager.field_list(target)
  end

  def reserve(target, fieldname, type)
    r = @engine.reserve(target, fieldname, type)
    !!r
  end

  def send(target, events)
    r = @engine.send(target, events)
    !!r
  end

  def event(query_name)
    @engine.output_pool.pop(query_name)
  end

  def sweep
    @engine.output_pool.sweep
  end

  # post('/listen') # get all events as stream, during connection keepaliving
end
