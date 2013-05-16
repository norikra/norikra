class Norikra::RPC::Handler
  def initialize(engine)
    @engine = engine
  end

  def targets
    @engine.targets
  end

  def queries
    @engine.queries.map(&:to_hash)
  end

  def add_query(query_name, expression)
    @engine.register(Norikra::Query.new(:name => query_name, :expression => expression))
  end

  def typedefs
    @engine.typedef_manager.dump
  end
  # def add_typedefs; end #TODO: typedef ? field with type ?

  def send(target, events)
    @engine.send(target, events)
    true
  end

  def event(query_name)
    @engine.output_pool.pop(query_name)
  end

  def sweep
    @engine.output_pool.sweep
  end

  # post('/listen') # get all events as stream, during connection keepaliving
end
