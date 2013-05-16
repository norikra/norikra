require 'norikra/typedef'

module Norikra
  class TypedefManager
    attr_reader :typedefs

    def initialize(opts={})
      @typedefs = {} # target => {[sorted_keys].freeze => typedef}
    end

    def dump
      ret = {}
      @typedefs.keys.sort.each do |target|
        ret[target] ||= {}
        @typedefs[target].keys.each do |key|
          ret[target][key] = @typedefs[target][key].to_hash
        end
      end
      ret
    end

    def store(target, typedef)
      # stores pre-defined definition
      @typedefs[target] ||= {}
      @typedefs[target][typedef.definition.keys.sort.join(',').freeze] = typedef
    end

    def refer(target, data)
      typedef_key = data.keys.sort.join(',').freeze
      @typedefs[target] ||= {}
      @typedefs[target][typedef_key] ||= Norikra::Typedef.simple_guess(data)
      @typedefs[target][typedef_key]
    end
  end
end
