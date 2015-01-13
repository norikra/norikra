module Norikra
  class Target
    attr_accessor :name, :fields, :auto_field, :last_modified

    def self.valid?(target_name)
      target_name =~ /^[a-zA-Z]([_a-zA-Z0-9]*[a-zA-Z0-9])?$/
    end

    def initialize(name, fields=[], auto_field=true)
      @name = name
      @fields = fields
      @auto_field = !!auto_field
      @last_modified = nil
    end

    def <=>(other)
      self.name <=> other.name
    end

    def to_hash
      {name: @name, auto_field: @auto_field}
    end

    def ==(other)
      self.class == other.class ? self.name == other.name : self.name == other.to_s
    end

    def auto_field?
      @auto_field
    end

    def update!
      @last_modified = Time.now
    end
  end
end
