require 'norikra/error'
require 'norikra/query'

module Norikra
  class SuspendedQuery
    attr_accessor :name, :group, :expression, :targets

    def initialize(query)
      @name = query.name
      @group = query.group
      @expression = query.expression
      @targets = query.targets
    end

    def <=>(other)
      if @group.nil? || other.group.nil?
        if @group.nil? && other.group.nil?
          @name <=> other.name
        else
          @group.to_s <=> other.group.to_s
        end
      else
        if @group == other.group
          self.name <=> other.name
        else
          self.group <=> other.group
        end
      end
    end

    def suspended?
      true
    end

    def to_hash
      {'name' => @name, 'group' => @group, 'expression' => @expression, 'targets' => @targets, 'suspended' => true}
    end

    def create
      Query.new(name: @name, group: @group, expression: @expression)
    end
  end
end
