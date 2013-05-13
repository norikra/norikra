module Norikra
  class Query
    attr_accessor :name, :tablename, :expression

    def initialize(param={})
      @name = param[:name]
      @tablename = param[:tablename]
      @expression = param[:expression]
    end

    def to_hash
      {'name' => @name, 'tablename' => @tablename, 'expression' => @expression}
    end
  end
end
