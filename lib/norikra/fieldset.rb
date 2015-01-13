require 'digest'
require 'norikra/field'

module Norikra
  class FieldSet
    attr_accessor :summary, :fields
    attr_accessor :target, :level, :query_unique_keys

    # fieldset doesn't have container fields
    def initialize(fields, default_optional=nil, rebounds=0, query_unique_keys=[])
      @fields = {}
      # fields.keys are raw key for container access chains
      fields.keys.each do |key|
        data = fields[key]
        if data.is_a?(Norikra::Field)
          @fields[data.name] = data
        elsif data.is_a?(Hash)
          type = data[:type].to_s
          optional = data.has_key?(:optional) ? data[:optional] : default_optional
          @fields[key.to_s] = Field.new(key.to_s, type, optional, !!data[:nullable])
        elsif data.is_a?(String) || data.is_a?(Symbol)
          @fields[key.to_s] = Field.new(key.to_s, data.to_s, default_optional)
        else
          raise ::ArgumentError, "FieldSet.new argument class unknown: #{fields.class}"
        end
      end
      self.update_summary

      @target = nil
      @level = nil
      @rebounds = rebounds
      @query_unique_keys = query_unique_keys
      @event_type_name = nil
    end

    def dup
      fields = Hash[@fields.map{|key,field| [key, {type: field.type, optional: field.optional, nullable: field.nullable?}]}]
      self.class.new(fields, nil, @rebounds, @query_unique_keys)
    end

    def self.leaves(container)
      unless container.is_a?(Array) || container.is_a?(Hash)
        raise ::ArgumentError, "FieldSet#leaves accepts Array or Hash only"
      end
      return [] if container.empty?

      # returns list of [ [key-chain-items-flatten-list, value] ]
      dig = Proc.new do |obj|
        if obj.is_a?(Array)
          ary = []
          obj.each_with_index do |v,i|
            if v.is_a?(Hash) || v.is_a?(Array)
              ary += dig.call(v).map{|chain| [i] + chain}
            else
              ary.push([i, v])
            end
          end
          ary
        else # Hash
          obj.map {|k,v|
            if k.nil?
              []
            elsif v.is_a?(Hash) || v.is_a?(Array)
              if v.empty?
                []
              else
                dig.call(v).map{|chain| [k] + chain}
              end
            else
              [[k, v]]
            end
          }.reduce(:+)
        end
      end
      dig.call(container)
    end

    #### field_names_key is for lookup FieldSet from event data
    # field_names_key: a,b,c,d
    ### comma separated field names, which contains valid values (null fields are not included)
    def self.field_names_key(data, fieldset=nil, strict=false, additional_fields=[])
      if !fieldset && strict
        raise RuntimeError, "strict(true) cannot be specified with fieldset=nil"
      end

      unless fieldset
        return data.reject{|k,v| v.respond_to?(:nullable?) && v.nullable? }.keys.sort.join(',')
      end

      keys = []
      optionals = []

      fieldset.fields.each do |key,field|
        if field.optional?
          optionals.push(field.name)
        else
          keys.push(field.name)
        end
      end
      optionals += additional_fields

      Norikra::FieldSet.leaves(data).each do |chain|
        value = chain.pop
        key = Norikra::Field.regulate_key_chain(chain).join('.')
        unless keys.include?(key)
          if optionals.include?(key) || (!strict && chain.size == 1)
            keys.push(key)
          end
        end
      end

      keys.sort.join(',')
    end

    def field_names_key
      self.class.field_names_key(@fields)
    end

    # summary is for checks whether FieldSet is already registered or not
    def update_summary
      @summary = @fields.keys.sort.map{|k| f = @fields[k]; "#{f.escaped_name}:#{f.type}" + (f.nullable? ? ':nullable' : '')}.join(',')
      self
    end

    def update(fields, optional_flag)
      fields.each do |field|
        @fields[field.name] = field.dup(optional_flag)
      end
      self.update_summary
    end

    def nullable_diff(fieldset) # data_fieldset.nullable_diff(query_fieldset)
      fieldset.fields.select{|fname, f| !self.fields[fname] && f.nullable? }.values
    end

    def ==(other)
      return false if self.class != other.class
      self.summary == other.summary && self.query_unique_keys == other.query_unique_keys
    end

    def definition
      d = {}
      @fields.each do |key, field|
        d[field.escaped_name] = field.esper_type
      end
      d
    end

    def subset?(other) # self is subset of other (or not)  ### query_fieldset.subset?(fieldset_referred_from_event_data)
      ### nullable fields can be ignored (to be updated later, with nullable fields ignored here)
      (self.fields.keys - other.fields.keys).reject{|fname| @fields[fname].nullable? }.size < 1
    end

    def event_type_name
      @event_type_name.dup
    end

    def bind(target, level, type_name_update=false)
      @target = target
      @level = level
      prefix = case level
               when :base then 'b_'
               when :query then 'q_'
               when :data then 'e_' # event
               else
                 raise ::ArgumentError, "unknown fieldset bind level: #{level}, for target #{target}"
               end
      @rebounds += 1 if type_name_update
      query_unique_key = @query_unique_keys ? @query_unique_keys.join("\t") : ''

      @event_type_name = prefix + Digest::MD5.hexdigest([target, level.to_s, @rebounds.to_s, query_unique_key, @summary].join("\t"))
      self
    end

    def rebind(type_name_update, query_fieldset=nil)
      renew = self.dup
      if query_fieldset
        diff = self.nullable_diff(query_fieldset)
        renew.update(diff, true) unless diff.empty? # all nullable fields are optional
      end
      renew.bind(@target, @level, type_name_update)
    end

    def format(data)
      # all keys of data should be already known at #format (before #format, do #refer)
      ret = {}
      @fields.each do |key,field|
        ret[field.escaped_name] = field.format(field.value(data))
      end
      ret
    end
  end
end
