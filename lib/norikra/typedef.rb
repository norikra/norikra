require 'digest'

module Norikra
  class Typedef
    attr_accessor :name, :definition

    def initialize(param={})
      @definition = self.class.mangle_symbols(param[:definition])
      @name = param[:name] || Digest::MD5.hexdigest(@definition.inspect)
    end

    def ==(other)
      self.name == other.name
    end

    # string  A single character to an unlimited number of characters.
    # boolean A boolean value.
    # integer An integer value (4 byte).
    # long    A long value (8 byte). Use the "L" or "l" (lowercase L) suffix. # select 1L as field1, 1l as field2
    # double  A double-precision 64-bit IEEE 754 floating point.              # select 1.67 as field1, 167e-2 as field2, 1.67d as field3
    # float   A single-precision 32-bit IEEE 754 floating point. Use the "f" suffix. # select 1.2f as field1, 1.2F as field2
    # byte    A 8-bit signed two's complement integer.                        # select 0x10 as field1
    def match?(target)
      target.keys.each do |k|
        return false unless @definition.has_key?(k)

        type = @definition[k]
        value = target[k]

        ret = case type
              when 'string'
                value.is_a?(String)
              when 'boolean'
                value.is_a?(TrueClass) || value.is_a?(FalseClass) || (value.is_a?(String) && value =~ /^(?:true|false)$/i)
              when 'long', 'integer'
                value.is_a?(Integer) || (value.is_a?(String) && value =~ /^-?\d+[lL]?$/)
              when 'double', 'float'
                value.is_a?(Float) || value.is_a?(Integer) || (value.is_a?(String) && value =~ /^-?\d+(\.\d+)?(?:[eE]-?\d+|[dDfF])?$/)
              end
        return false unless ret
      end
      true
    end

    def self.guess(data)
      definition = {}
      data.keys.sort.each do |key|
        val = data[key]
        sval = val.to_s
        case
        when val.is_a?(TrueClass) || val.is_a?(FalseClass) || sval =~ /^(?:true|false)$/i
          definition[key.to_s] = 'boolean'
        when val.is_a?(Integer) || sval =~ /^-?\d+[lL]?$/
          definition[key.to_s] = 'long'
        when val.is_a?(Float) || sval =~ /^-?\d+\.\d+(?:[eE]-?\d+|[dDfF])?$/
          definition[key.to_s] = 'double'
        else
          definition[key.to_s] = 'string'
        end
      end
      self.new(:definition => definition)
    end

    def self.mangle_symbols(hash)
      ret = hash.dup
      ret.keys.select{|k| k.is_a?(Symbol)}.each do |s|
        ret[s.to_s] = ret.delete(s)
      end
      ret
    end
  end
end
