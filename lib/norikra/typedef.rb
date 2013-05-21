require 'digest'
require 'json'

# Norikra::Field, Norikra::FieldSet, Norikra::Typedef

module Norikra
  class Field
    attr_accessor :name, :type, :optional

    def initialize(name, type, optional=nil)
      @name = name.to_s
      @type = self.class.valid_type?(type)
      @optional = optional
    end

    def to_hash
      {'name' => @name, 'type' => @type, 'optional' => @optional}
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
    #### 'integer' in epser document IS WRONG.
    #### If 'integer' specified, esper raises this exception:
    ### Exception: Nestable type configuration encountered an unexpected property type name 'integer' for property 'status',
    ### expected java.lang.Class or java.util.Map or the name of a previously-declared Map or ObjectArray type
    #### Correct type name is 'int'. see and run 'junks/esper-test.rb'
    def self.valid_type?(type)
      case type.to_s.downcase
      when 'string' then 'string'
      when 'boolean' then 'boolean'
      when 'int' then 'int'
      when 'long' then 'long'
      when 'float' then 'float'
      when 'double' then 'double'
      else
        raise ArgumentError, "invalid field type #{type}"
      end
    end

    def format(value)
      case @type
      when 'string'  then value.to_s
      when 'boolean' then value =~ /^(true|false)$/i ? ($1.downcase == 'true') : (!!value)
      when 'long','int' then value.to_i
      when 'double','float' then value.to_f
      else
        raise RuntimeError, "unknown field type (in format), maybe BUG. name:#{@name},type:#{@type}"
      end
    end
  end

  class FieldSet
    attr_accessor :summary, :fields
    attr_accessor :target, :level

    def initialize(fields, default_optional=nil)
      @fields = {}
      fields.keys.each do |key|
        data = fields[key]
        type,optional = if data.is_a?(Hash)
                          [data[:type], (data.has_key?(:optional) ? data[:optional] : default_optional)]
                        elsif data.is_a?(String)
                          [data, default_optional]
                        else
                          raise ArgumentError, "FieldSet.new argument class unknown: #{fields.class}"
                        end
        @fields[key.to_s] = Field.new(key, type, optional)
      end
      self.update_summary

      @target = nil
      @level = nil
      @event_type_name = nil
    end

    def dup
      fields = Hash[@fields.map{|key,field| [key, {:type => field.type, :optional => field.optional}]}]
      self.class.new(fields)
    end

    def field_names_key
      @fields.keys.sort.join(',')
    end

    def update_summary
      @summary = @fields.keys.sort.map{|k| @fields[k].name + ':' + @fields[k].type}.join(',')
      self
    end

    def update(fields, optional_flag)
      fields.each do |field|
        @fields[field.name] = field.dup(optional_flag)
      end
      self.update_summary
    end

    #TODO: have a bug?
    def ==(other)
      return false unless self.class != other.class
      self.summary == other.summary
    end

    def definition
      d = {}
      @fields.each do |key, field|
        d[field.name] = field.type
      end
      d
    end

    def subset?(other) # self is subset of other (or not)
      (self.fields.keys - other.fields.keys).size == 0
    end

    def event_type_name
      @event_type_name.dup
    end

    def bind(target, level)
      @target = target
      @level = level
      prefix = case level
               when :base then 'b_'
               when :query then 'q_'
               else 'e_'
               end
      @event_type_name = prefix + Digest::MD5.hexdigest(target + "\t" + level.to_s + "\t" + @summary)
      self
    end

    def self.simple_guess(data, optional=true)
      mapping = Hash[
        data.map{|key,value|
          type = case value
                 when TrueClass,FalseClass then 'boolean'
                 when Integer then 'long'
                 when Float   then 'double'
                 else
                   'string'
                 end
          [key,type]
        }
      ]
      self.new(mapping, optional)
    end

    # def self.guess(data, optional=true)
    #   mapping = Hash[
    #     data.map{|key,value|
    #       sval = value.to_s
    #       type = case
    #              when val.is_a?(TrueClass) || val.is_a?(FalseClass) || sval =~ /^(?:true|false)$/i
    #                'boolean'
    #              when val.is_a?(Integer) || sval =~ /^-?\d+[lL]?$/
    #                'long'
    #              when val.is_a?(Float) || sval =~ /^-?\d+\.\d+(?:[eE]-?\d+|[dDfF])?$/
    #                'double'
    #              else
    #                'string'
    #              end
    #       [key,type]
    #     }
    #   ]
    #   self.new(mapping, optional)
    # end
  end

  # Typedef is
  #  * known field list of target (and these are optional or not)
  #  * known field-set list of a target
  #  * base set of a target
  class Typedef
    attr_accessor :fields, :baseset, :queryfieldsets, :datafieldsets

    def initialize(fields=nil)
      if fields
        @baseset = FieldSet.new(fields, false) # all fields are required
        @fields = @baseset.fields.dup
      else
        @baseset = nil
        @fields = {}
      end

      @queryfieldsets = []
      @datafieldsets = []

      @set_map = {} # fieldname.sort.join(',') => data_fieldset

      @mutex = Mutex.new
    end

    def field_defined?(list)
      list.reduce(true){|r,f| r && @fields[f]}
    end

    def lazy?
      @baseset.nil?
    end

    def activate(fieldset)
      @mutex.synchronize do
        set = fieldset.dup
        fieldset.fields.dup.each do |fieldname, field|
          set.fields[fieldname] = field.dup(false)
        end
        @baseset = set
        @fields = @baseset.fields.merge(@fields)
      end
    end

    def reserve(fieldname, type, optional=true)
      fieldname = fieldname.to_s
      @mutex.synchronize do
        return false if @fields[fieldname]
        @fields[fieldname] = Field.new(fieldname, type, optional)
      end
      true
    end

    def consistent?(fieldset)
      fields = fieldset.fields
      @baseset.subset?(fieldset) &&
        @fields.values.select{|f| !f.optional? }.reduce(true){|r,f| r && fields[f.name] && fields[f.name].type == f.type} &&
        fields.values.reduce(true){|r,f| r && (@fields[f.name].nil? || @fields[f.name].type == f.type)}
    end

    def push(level, fieldset)
      unless self.consistent?(fieldset)
        raise ArgumentError, "inconsistent field set for this typedef"
      end

      @mutex.synchronize do
        case level
        when :base
          unless @baseset.object_id == fieldset.object_id
            raise RuntimeError, "baseset mismatch"
          end
        when :query
          unless @queryfieldsets.include?(fieldset)
            @queryfieldsets.push(fieldset)

            fieldset.fields.each do |fieldname,field|
              @fields[fieldname] = field.dup(true) unless @fields[fieldname]
            end
          end
        when :data
          unless @datafieldsets.include?(fieldset)
            @datafieldsets.push(fieldset)
            @set_map[fieldset.field_names_key] = fieldset

            fieldset.fields.each do |fieldname,field|
              @fields[fieldname] = field.dup(true) unless @fields[fieldname]
            end
          end
        else
          raise ArgumentError, "unknown level #{level}"
        end
      end
      true
    end

    def refer(data)
      field_names_key = data.keys.sort.join(',')
      return @set_map[field_names_key] if @set_map.has_key?(field_names_key)

      guessed = FieldSet.simple_guess(data)
      guessed_fields = guessed.fields
      @fields.each do |key,field|
        if guessed_fields.has_key?(key)
          guessed_fields[key].type = field.type if guessed_fields[key].type != field.type
        else
          guessed_fields[key] = field unless field.optional?
        end
      end
      guessed
    end

    def format(data)
      # all keys of data should be already known at #format (before #format, do #refer)
      ret = {}
      data.each do |key, value|
        ret[key] = @fields[key].format(value)
      end
      ret
    end
  end
end
