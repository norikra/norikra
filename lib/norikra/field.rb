require 'norikra/error'

module Norikra
  class Field
    ### norikra types
    # string
    # boolean (alias: bool)
    # integer (alias: int, long)
    # float   (alias: double)
    # hash
    # array

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
    #             Hash key item as "String of Numbers" be escaped with '$$'.
    #             # select h.$$3 #<= "h":{"3":3}
    #
    # array   A single value which is represented as Array class (ex: parsed json array), and can be nested with hash/array
    #             # select h.$0, h.$1.$0.name        #<= "h":["....", [{"name":"value..."}]]
    #
    #### 'integer' in epser document IS WRONG.
    #### If 'integer' specified, esper raises this exception:
    ### Exception: Nestable type configuration encountered an unexpected property type name 'integer' for property 'status',
    ### expected java.lang.Class or java.util.Map or the name of a previously-declared Map or ObjectArray type
    #### Correct type name is 'int'. see and run 'junks/esper-test.rb'

    attr_accessor :name, :type, :esper_type, :optional, :escaped_name, :container_name, :container_type

    def self.esper_type_map(type)
      case type.to_s.downcase
      when 'string' then 'string'
      when 'boolean', 'bool' then 'boolean'
      when 'integer', 'int', 'long' then 'long'
      when 'float', 'double' then 'double'
      when 'hash', 'array'
        raise Norikra::ArgumentError, "#{type} is norikra internal type, not for esper"
      when 'byte'
        raise Norikra::ArgumentError, "byte is not supported in Norikra"
      else
        raise Norikra::ArgumentError, "unknown type:#{type}"
      end
    end

    def self.container_type?(type)
      case type.to_s.downcase
      when 'hash','array' then true
      else
        false
      end
    end

    def self.valid_type(type)
      case type.to_s.downcase
      when 'string' then 'string'
      when 'boolean', 'bool' then 'boolean'
      when 'integer', 'int', 'long' then 'integer'
      when 'float', 'double' then 'float'
      when 'hash' then 'hash'
      when 'array' then 'array'
      when 'byte'
        raise Norikra::ArgumentError, "byte is not supported in Norikra"
      else
        raise Norikra::ArgumentError, "invalid field type '#{type}'"
      end
    end

    def initialize(name, type, optional=nil)
      @name = name.to_s
      @type = self.class.valid_type(type)
      @optional = optional

      @escaped_name = self.class.escape_name(@name)

      @container_name = @container_type = nil

      @chained_access = !!@name.index('.')
      if @chained_access
        parts = @name.split(/(?<!\.)\./)
        @container_name = parts[0]
        @container_type = parts[1] =~ /^(\$)?\d+$/ ? 'array' : 'hash'
        @optional = true
      end

      define_value_accessor(@name, @chained_access)
    end

    def chained_access?
      @chained_access
    end

    def container_field?
      self.class.container_type?(@type)
    end

    def esper_type
      self.class.esper_type_map(@type)
    end

    def self.escape_name(name)
      # hoge.pos #=> "hoge$pos"
      # hoge.0   #=> "hoge$$0"
      # hoge.$0  #=> "hoge$$0"
      # hoge.$$0 #=> "hoge$$$0"

      # hoge..pos #=> "hoge$_pos"
      # hoge...pos #=> "hoge$__pos"

      parts = name.split(/(?<!\.)\./).map do |part|
        if part =~ /^\d+$/
          '$' + part.to_s
        else
          part.gsub(/[^$_a-zA-Z0-9]/,'_')
        end
      end
      parts.join('$')
    end

    def self.unescape_name(name)
      if name.index('$')
        name.split(/(?<!\$)\$/).join('.')
      else
        name
      end
    end

    def self.regulate_key_chain(keys)
      keys.map{|key|
        case
        when key.is_a?(Integer) then '$' + key.to_s
        when key.is_a?(String) && key =~ /^[0-9]+$/ then '$$' + key.to_s
        else key.to_s.gsub(/[^$_a-zA-Z0-9]/,'_')
        end
      }
    end

    def self.escape_key_chain(*keys)
      # "hoge", "pos" #=> "hoge$pos"
      # "hoge", 3     #=> "hoge$$3"
      # "hoge", "3"   #=> "hoge$$$3"
      # "hoge", ".pos" #=> "hoge
      regulate_key_chain(keys).join('$')
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

    # def value(event) # by define_value_accessor

    def format(value, element_path=nil) #element_path ex: 'fname.fchild', 'fname.$0', 'f.fchild.$2'
      case @type
      when 'string'  then value.to_s
      when 'boolean' then value =~ /^(true|false)$/i ? ($1.downcase == 'true') : (!!value)
      when 'integer' then value.to_i
      when 'float' then value.to_f
      when 'hash', 'array'
        raise RuntimeError, "container field not permitted to access directly, maybe BUG. name:#{@name},type:#{@type}"
      else
        raise RuntimeError, "unknown field type (in format), maybe BUG. name:#{@name},type:#{@type}"
      end
    end

    def define_value_accessor(name, chained)
      # "fieldname" -> def value(event) ; event["fieldname"] ; end
      # "fieldname.key1" -> def value(event) ; event["fieldname"]["key1"] ; end
      # "fieldname.key1.$$2" -> def value(event) ; event["fieldname"]["key1"]["2"] ; end
      # "fieldname.2" -> def value(event) ; event["fieldname"][2] ; end
      # "fieldname.$2" -> def value(event) ; event["fieldname"][2] ; end

      unless chained
        @accessors = [name]
        self.instance_eval do
          def value(event)
            event[@accessors.first]
          end
        end
        return
      end

      @accessors = name.split(/(?<!\.)\./).map do |part|
        case part
        when /^\d+$/ then part.to_i
        when /^\$(\d+)$/ then $1.to_i
        when /^\$\$(\d+)$/ then $1.to_s
        else part
        end
      end
      self.instance_eval do
        def safe_fetch(v, accessor)
          unless accessor.is_a?(String) || accessor.is_a?(Fixnum)
            raise ArgumentError, "container_accessor must be a String or Interger, but #{accessor.class.to_s}"
          end
          if v.is_a?(Hash)
            # v[accessor] || v[accessor.to_s]
            if v.has_key?(accessor)
              v[accessor]
            elsif v.has_key?(accessor.to_s)
              v[accessor.to_s]
            elsif accessor.is_a?(String)
              val = v.keys.reduce(nil) do |r, key|
                if key.is_a?(String)
                  r || ( key.gsub(/[^$_a-zA-Z0-9]/, '_') == accessor.to_s ? v[key] : nil )
                else
                  r
                end
              end
              val # valid value or nil
            else # v does not have key "#{accessor}" and accessor is Fixnum
              nil
            end
          elsif v.is_a?(Array)
            if accessor.is_a?(Fixnum)
              v[accessor]
            else # String -> Hash expected
              nil
            end
          else # non-container value
            nil
          end
        end
        def value(event)
          @accessors.reduce(event){|e,a| safe_fetch(e, a)}
        end
      end
    end
  end
end
