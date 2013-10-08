require 'norikra/error'

module Norikra
  class Field
    ### esper types
    ### http://esper.codehaus.org/esper-4.9.0/doc/reference/en-US/html/epl_clauses.html#epl-syntax-datatype
    # string  A single character to an unlimited number of characters.
    # boolean A boolean value.
    # integer An integer value (4 byte).
    # long    A long value (8 byte). Use the "L" or "l" (lowercase L) suffix. # select 1L as field1, 1l as field2
    # double  A double-precision 64-bit IEEE 754 floating point.              # select 1.67 as field1, 167e-2 as field2, 1.67d as field3
    # float   A single-precision 32-bit IEEE 754 floating point. Use the "f" suffix. # select 1.2f as field1, 1.2F as field2
    # byte    A 8-bit signed two's complement integer.                        # select 0x10 as field1
    #
    ### norikra types of container
    # hash    A single value which is represented as Hash class (ex: parsed json object), and can be nested with hash/array
    #             # select h.value1, h.value2.value3 #<= "h":{"value1":"...","value2":{"value3":"..."}}
    # array   A single value which is represented as Array class (ex: parsed json array), and can be nested with hash/array
    #             # select h.$0, h.$1.$0.name        #<= "h":["....", [{"name":"value..."}]]
    #
    #### 'integer' in epser document IS WRONG.
    #### If 'integer' specified, esper raises this exception:
    ### Exception: Nestable type configuration encountered an unexpected property type name 'integer' for property 'status',
    ### expected java.lang.Class or java.util.Map or the name of a previously-declared Map or ObjectArray type
    #### Correct type name is 'int'. see and run 'junks/esper-test.rb'

    attr_accessor :name, :type, :optional

    def initialize(name, type, optional=nil)
      @name = name.to_s
      @type = self.class.valid_type?(type)
      @optional = optional
    end

    def to_hash(sym=false)
      if sym
        {name: @name, type: @type, optional: @optional}
      else
        {'name' => @name, 'type' => @type, 'optional' => @optional}
      end
    end

    def dup(optional=nil)
      self.class.new(@name, @type, optional.nil? ? @optional : optional)
    end

    def ==(other)
      self.name == other.name && self.type == other.type && self.optional == other.optional
    end

    def optional? # used outside of FieldSet
      @optional
    end

    def self.valid_type?(type)
      case type.to_s.downcase
      when 'string' then 'string'
      when 'boolean' then 'boolean'
      when 'int' then 'int'
      when 'long' then 'long'
      when 'float' then 'float'
      when 'double' then 'double'
      when 'hash' then 'hash'
      when 'array' then 'array'
      else
        raise Norikra::ArgumentError, "invalid field type '#{type}'"
      end
    end

    def format(value, element_path=nil) #element_path ex: 'fname.fchild', 'fname.$0', 'f.fchild.$2'
      case @type
      when 'string'  then value.to_s
      when 'boolean' then value =~ /^(true|false)$/i ? ($1.downcase == 'true') : (!!value)
      when 'long','int' then value.to_i
      when 'double','float' then value.to_f
      when 'hash'
        #TODO: ... ...
      when 'array'
        #TODO: ... ...
      else
        raise RuntimeError, "unknown field type (in format), maybe BUG. name:#{@name},type:#{@type}"
      end
    end
  end
end
