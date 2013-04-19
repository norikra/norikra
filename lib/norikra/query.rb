module Norikra
  class Query
    def initialize(expression)
      @expression = expression
      # dynamic statement parse/analysis?
      # composite from expression template & tablname attribute?
    end

    def tablename
    end

    def window
    end
  end
end
