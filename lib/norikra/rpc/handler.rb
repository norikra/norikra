class Norikra::RPC::Handler
  def initialize(engine)
    @engine = engine
  end

  def tables
    @engine.tables
  end

  def queries
    @engine.queries.map(&:to_hash)
  end

  def add_query(table_name, query_name, expression)
    @engine.add_query(Norikra::Query.new(:name => query_name, :tablename => table_name, :expression => expression))
  end

  # def typedefs; end
  # def add_typedefs; end #TODO: typedef ? field with type ?

  def sendevents(tablename, events)
    @engine.send(tablename, events)
  end

  def event(query_name)
    @engine.output_pool.pop(query_name)
  end

  def sweep
    @engine.output_pool.sweep
  end

  # post('/listen') # get all events as stream, during connection keepaliving
end
