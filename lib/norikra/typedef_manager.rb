require 'norikra/typedef'

module Norikra
  class TypedefManager
    attr_reader :typedefs

    def initialize(opts={})
      @typedefs = {} # tablename => {[sorted_keys].freeze => typedef}
    end

    def dump
      ret = {}
      @typedefs.keys.sort.each do |tablename|
        ret[tablename] ||= {}
        @typedefs[tablename].keys.each do |key|
          ret[tablename][key] = @typedefs[tablename][key].to_hash
        end
      end
      ret
    end

    def store(tablename, typedef)
      # stores pre-defined definition
      @typedefs[tablename] ||= {}
      @typedefs[tablename][typedef.definition.keys.sort.join(',').freeze] = typedef
    end

    def refer(tablename, data)
      typedef_key = data.keys.sort.join(',').freeze
      @typedefs[tablename] ||= {}
      @typedefs[tablename][typedef_key] ||= Norikra::Typedef.simple_guess(data)
      @typedefs[tablename][typedef_key]
    end
  end
end
