require 'norikra/typedef'

module Norikra
  class Query
    attr_accessor :name, :tablename, :typedef, :expression

    def initialize(param={})
      @name = param[:name]
      @tablename = param[:tablename]
      @expression = param[:expression]
    end
  end
end
