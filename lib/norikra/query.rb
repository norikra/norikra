require 'norikra/typedef'

module Norikra
  class Query
    attr_accessor :tablename, :typedef, :expression

    def initialize(param={})
      @tablename = param[:tablename]
      @typedef = param[:typedef] # TODO: typedef validation with Norikra::Typedef ?
      if @typedef.is_a?(Hash)
        @typedef = Norikra::Typedef.new(:definition => @typedef)
      end
      @expression = param[:expression]
    end
  end
end
