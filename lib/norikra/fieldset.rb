require 'digest'
require 'norikra/field'

module Norikra
  class FieldSet
    attr_accessor :summary, :fields
    attr_accessor :target, :level

    def initialize(fields, default_optional=nil, rebounds=0)
      @fields = {}
      fields.keys.each do |key|
        data = fields[key]
        type,optional = if data.is_a?(Hash)
                          [data[:type].to_s, (data.has_key?(:optional) ? data[:optional] : default_optional)]
                        elsif data.is_a?(String) || data.is_a?(Symbol)
                          [data.to_s, default_optional]
                        else
                          raise ArgumentError, "FieldSet.new argument class unknown: #{fields.class}"
                        end
        @fields[key.to_s] = Field.new(key.to_s, type, optional)
      end
      self.update_summary

      @target = nil
      @level = nil
      @rebounds = rebounds
      @event_type_name = nil
    end

    def dup
      fields = Hash[@fields.map{|key,field| [key, {:type => field.type, :optional => field.optional}]}]
      self.class.new(fields, nil, @rebounds)
    end

    def self.field_names_key(data, fieldset=nil)
      if fieldset
        keys = []
        fieldset.fields.each do |key,field|
          unless field.optional?
            keys.push(key)
          end
        end
        data.keys.each do |key|
          keys.push(key) unless keys.include?(key)
        end
        keys.sort.join(',')
      else
        data.keys.sort.join(',')
      end
    end

    def field_names_key
      self.class.field_names_key(@fields)
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
      return false if self.class != other.class
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

    def bind(target, level, update_type_name=false)
      @target = target
      @level = level
      prefix = case level
               when :base then 'b_'
               when :query then 'q_'
               when :data then 'e_' # event
               else
                 raise ArgumentError, "unknown fieldset bind level: #{level}, for target #{target}"
               end
      @rebounds += 1 if update_type_name

      @event_type_name = prefix + Digest::MD5.hexdigest([target, level.to_s, @rebounds.to_s, @summary].join("\t"))
      self
    end

    def rebind(update_type_name)
      self.dup.bind(@target, @level, update_type_name)
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
end
