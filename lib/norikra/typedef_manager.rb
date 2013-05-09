require 'norikra/typedef'

module Norikra
  class TypedefManager
    attr_reader :strict_check

    def initialize(opts={})
      @def_map = {} # tablename => {[sorted_keys].freeze => typedef}
    end

    def store(tablename, typedef)
      # stores pre-defined definition
      @def_map[tablename] ||= {}
      @def_map[tablename][typedef.definition.keys.sort.freeze] = typedef
    end

    def refer(tablename, data)
      @def_map[tablename] ||= {}
      @def_map[tablename][data.keys.sort.freeze] ||= Norikra::Typedef.simple_guess(data)
    end
  end
end
