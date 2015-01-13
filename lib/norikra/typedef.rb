require 'json'

require 'norikra/error'

require 'norikra/field'
require 'norikra/fieldset'

module Norikra
  # Typedef is
  #  * known field list of target (and these are optional or not), and container fields
  #  * known field-set list of a target
  #  * base set of a target

  class Typedef
    attr_accessor :fields, :container_fields, :waiting_fields ,:baseset, :queryfieldsets, :datafieldsets

    def initialize(fields=nil)
      @container_fields = {}

      if fields && !fields.empty?
        given_set = FieldSet.new(fields, false) # default_optional=false, but chained access fields are always optional
        @fields = given_set.fields.dup
        base_fields = {}
        @fields.values.each do |field|
          if !field.optional?
            base_fields[field.name] = field
          elsif field.chained_access?
            cname = field.container_name
            @container_fields[cname] = Norikra::Field.new(cname, field.container_type, true)
          end
        end
        @baseset = FieldSet.new(base_fields, false)
      else
        @baseset = nil
        @fields = {}
      end

      @waiting_fields = []

      @queryfieldsets = []
      @datafieldsets = []

      # FieldSet.field_names_key(data_fieldset, fieldset) => data_fieldset
      ### field_names_key is built by keys w/ data, without null fields
      ### data_fieldset includes null fields
      @set_map = {}

      @mutex = Mutex.new
    end

    def field_defined?(list)
      # used for only queries: TypedefManager#ready?(query) and TypedefManager#generate_field_mapping(query)
      #  be not needed to think about containers
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
        @baseset.fields.each do |name,f|
          @waiting_fields.delete(name) if @waiting_fields.include?(name)
        end
        @fields = @baseset.fields.merge(@fields)
      end
    end

    def reserve(fieldname, type, optional=true)
      fieldname = fieldname.to_s
      @mutex.synchronize do
        return false if @fields[fieldname]
        field = Norikra::Field.new(fieldname, type, optional)
        if @waiting_fields.include?(fieldname)
          @waiting_fields.delete(fieldname)
        end
        @fields[fieldname] = field
        if field.chained_access? && !@container_fields[field.container_name]
          container = Norikra::Field.new(field.container_name, field.container_type, true)
          @container_fields[field.container_name] = container
        end
      end
      true
    end

    def consistent?(fieldset)
      fields = fieldset.fields
      @baseset.subset?(fieldset) &&
        @fields.values.select{|f| !f.optional? }.reduce(true){|r,f| r && fields.has_key?(f.name) && fields[f.name].type == f.type} &&
        fields.values.reduce(true){|r,f| r && (!@fields.has_key?(f.name) || @fields[f.name].type == f.type)}
    end

    def push(level, fieldset)
      unless self.consistent?(fieldset)
        warn "fieldset mismatch", receiver: self, with: fieldset
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
              @waiting_fields.delete(fieldname) if @waiting_fields.include?(fieldname)
              @fields[fieldname] = field.dup(true) unless @fields[fieldname]
            end
          end
        when :data
          unless @datafieldsets.include?(fieldset)
            @datafieldsets.push(fieldset)
            @set_map[fieldset.field_names_key] = fieldset

            fieldset.fields.each do |fieldname,field|
              if @waiting_fields.include?(fieldname)
                @waiting_fields.delete(fieldname)
              end
              unless @fields[fieldname]
                @fields[fieldname] = field.dup(true)
                if field.chained_access? && !@container_fields[field.container_name]
                  @container_fields[field.container_name] = Norikra::Field.new(field.container_name, field.container_type, true)
                end
              end
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
        warn "fieldset mismatch", receiver: self, with: fieldset
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

    def simple_guess(data, opts={})
      #### in typedef_manager
      # guessed = @typedefs[target].simple_guess(event, strict: false, baseset: true)

      #### in Typedef#refer
      # guessed = self.simple_guess(data, strict: strict)

      flatten_key_value_pairs = []

      data.each do |key,value|
        next if opts[:strict] && !(@fields.has_key?(key) || @waiting_fields.include?(key) || value.is_a?(Hash) || value.is_a?(Array))

        if value.is_a?(Hash) || value.is_a?(Array)
          next if opts[:baseset]

          Norikra::FieldSet.leaves(value).map{|chain| [key] + chain}.each do |chain|
            value = chain.pop
            key = Norikra::Field.regulate_key_chain(chain).join('.')
            next unless @fields.has_key?(key) || @waiting_fields.include?(key)
            flatten_key_value_pairs.push([key, value])
          end
        else
          flatten_key_value_pairs.push([key, value])
        end
      end

      mapping = Hash[
        flatten_key_value_pairs.map{|key,value|
          type = case value
                 when TrueClass,FalseClass then {type: 'boolean'}
                 when Integer then {type: 'long'}
                 when Float   then {type: 'double'}
                 else {type: 'string'}
                 end
          [key,type]
        }
      ]

      FieldSet.new(mapping, false) # in simple_guess, optional is always false
    end

    def refer(data, strict=false)
      field_names_key = FieldSet.field_names_key(data, self, strict, @waiting_fields)
      return @set_map[field_names_key] if @set_map.has_key?(field_names_key)

      guessed = self.simple_guess(data, strict: strict)
      guessed_fields = guessed.fields
      @fields.each do |key,field|
        if guessed_fields.has_key?(key)
          guessed_fields[key].type = field.type if guessed_fields[key].type != field.type
          guessed_fields[key].optional = field.optional if guessed_fields[key].optional != field.optional
        else
          guessed_fields[key] = field unless field.optional?
        end
      end
      guessed.update_summary #=> guessed
    end

    def dump_all
      fields = {}
      @fields.each do |key,field|
        fields[field.name.to_sym] = field.to_hash(true)
      end
      fields
    end

    def dump # to cli display
      fields = {}
      @fields.each do |key,field|
        fields[key.to_sym] = field.to_hash(true) unless field.chained_access?
      end
      @container_fields.each do |key, field|
        fields[key.to_sym] = field.to_hash(true)
      end
      fields
    end
  end
end
