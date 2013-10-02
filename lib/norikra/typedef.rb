require 'json'

require 'norikra/error'

require 'norikra/field'
require 'norikra/fieldset'

module Norikra
  # Typedef is
  #  * known field list of target (and these are optional or not)
  #  * known field-set list of a target
  #  * base set of a target
  class Typedef
    attr_accessor :fields, :baseset, :queryfieldsets, :datafieldsets

    def initialize(fields=nil)
      if fields && !fields.empty?
        @baseset = FieldSet.new(fields, false) # all fields are required
        @fields = @baseset.fields.dup
      else
        @baseset = nil
        @fields = {}
      end

      @queryfieldsets = []
      @datafieldsets = []

      @set_map = {} # FieldSet.field_names_key(data_fieldset, fieldset) => data_fieldset

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
        set = fieldset.rebind(false) # base fieldset rebinding must not update event_type_name
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
        raise Norikra::ArgumentError, "field definition mismatch with already defined fields"
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

    def pop(level, fieldset)
      @mutex.synchronize do
        case level
        when :base
          raise RuntimeError, "BUG: pop of base fieldset is nonsense (typedef deletion?)"
        when :query
          @queryfieldsets.delete(fieldset) if @queryfieldsets.include?(fieldset)
        when :data
          raise RuntimeError, "BUG: pop of data fieldset is nonsense"
        else
          raise ArgumentError, "unknown level #{level}"
        end
      end
      true
    end

    def replace(level, old_fieldset, fieldset)
      unless self.consistent?(fieldset)
        raise Norikra::ArgumentError, "field definition mismatch with already defined fields"
      end
      if level != :data
        raise ArgumentError, "invalid argument, fieldset replace should be called for :data"
      end
      if old_fieldset.field_names_key != fieldset.field_names_key
        raise ArgumentError, "try to replace different field name sets"
      end
      @mutex.synchronize do
        @datafieldsets.delete(old_fieldset)
        @set_map[fieldset.field_names_key] = fieldset
        @datafieldsets.push(fieldset)
      end
      true
    end

    def refer(data)
      field_names_key = FieldSet.field_names_key(data, self)
      return @set_map[field_names_key] if @set_map.has_key?(field_names_key)

      guessed = FieldSet.simple_guess(data)
      guessed_fields = guessed.fields
      @fields.each do |key,field|
        if guessed_fields.has_key?(key)
          guessed_fields[key].type = field.type if guessed_fields[key].type != field.type
          guessed_fields[key].optional = field.optional if guessed_fields[key].optional != field.optional
        else
          guessed_fields[key] = field unless field.optional?
        end
      end
      guessed.update_summary
    end

    def format(data)
      # all keys of data should be already known at #format (before #format, do #refer)
      ret = {}
      data.each do |key, value|
        ret[key] = @fields[key].format(value)
      end
      ret
    end

    def dump
      fields = {}
      @fields.map{|key,field|
        fields[key.to_sym] = field.to_hash(true)
      }
      fields
    end
  end
end
