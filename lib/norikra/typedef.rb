require 'digest'

module Norikra
  class Typedef
    attr_accessor :name, :definition

    def initialize(param={})
      @definition = self.class.mangle_symbols(param[:definition])
      @name = param[:name] || Digest::MD5.hexdigest(@definition.inspect)
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
