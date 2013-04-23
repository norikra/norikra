require 'norikra/typedef'

module Norikra
  class TypeManager
    def initialize(opts)
      @strict_check = opts[:strict] || false
      @dict = {} # tablename => [typedefs]
    end

    def refer(tablename, data_batch)
    end
  end
end
