require 'norikra/typedef'

module Norikra
  class TypedefManager
    attr_reader :strict_check

    def initialize(opts={})
      @strict_check = opts[:strict] || false
    end

    def refer(data_batch)
      target_data_list = [data_batch.first]

      if @strict_check && data_batch.length > 1
        target_data_list = data_batch

      elsif data_batch.size > 1
        target_data_list.push(data_batch.last)

      end

      defs = {}
      target_data_list.map{|d| Norikra::Typedef.guess(d)}.each do |d|
        next if defs[d.name]
        defs[d.name] = d
      end
      defs.values
    end
  end
end
