require 'java'
require 'esper-4.9.0.jar'
require 'esper/lib/commons-logging-1.1.1.jar'
require 'esper/lib/antlr-runtime-3.2.jar'
require 'esper/lib/cglib-nodep-2.2.jar'

module Norikra
  class Query
    attr_accessor :name, :expression

    def initialize(param={})
      @name = param[:name]
      @expression = param[:expression]
      @ast = nil
      @tablename = nil
      @fields = nil
    end

    def dup
      self.class.new(:name => @name, :expression => @expression)
    end

    def to_hash
      {'name' => @name, 'tablename' => @tablename, 'expression' => @expression}
    end

    def tablename
      return @tablename if @tablename
      #TODO: this code doesn't care JOINs.
      @tablename = self.ast.find('STREAM_EXPR').find('EVENT_FILTER_EXPR').children.first.name
      @tablename
    end

    def fields
      return @fields if @fields
      #TODO: this code doesn't care JOINs.
      @fields = self.ast.listup('EVENT_PROP_SIMPLE').map{|p| p.children.first.name}.uniq.sort
      @fields
    end

    class ParseRuleSelectorImpl
      include com.espertech.esper.epl.parse.ParseRuleSelector
      def invokeParseRule(parser)
        parser.startEPLExpressionRule().getTree()
      end
    end

    class ASTNode
      attr_accessor :name, :children
      def initialize(name, children)
        @name = name
        @children = children
      end
      def to_a
        [@name] + @children.map(&:to_a)
      end
      def find(node_name) # only one, depth-first search
        return self if @name == node_name
        @children.each do |c|
          r = c.find(node_name)
          return r if r
        end
        nil
      end
      def listup(node_name)
        result = []
        result.push(self) if @name == node_name
        @children.each do |c|
          result.push(*c.listup(node_name))
        end
        result
      end
    end

    def ast
      return @ast if @ast
      rule = ParseRuleSelectorImpl.new
      target = @expression.dup
      forerrmsg = @expression.dup
      result = com.espertech.esper.epl.parse.ParseHelper.parse(target, forerrmsg, true, rule, false)

      def convSubTree(tree)
        ASTNode.new(tree.text, (tree.children ? tree.children.map{|c| convSubTree(c)} : []))
      end
      @ast = convSubTree(result.getTree)
      @ast
    end

    ### select max(price) as maxprice from HogeTable.win:time_batch(10 sec) where cast(amount, double) > 2 and price > 50
    # query.ast.to_a
    # ["EPL_EXPR",
    #  ["SELECTION_EXPR",
    #   ["SELECTION_ELEMENT_EXPR",
    #    ["LIB_FUNC_CHAIN",
    #     ["LIB_FUNCTION",
    #      ["max"],
    #      ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", ["price"]]],
    #      ["("]]],
    #    ["maxprice"]]],
    #  ["STREAM_EXPR",
    #   ["EVENT_FILTER_EXPR", ["HogeTable"]],
    #   ["VIEW_EXPR",
    #    ["win"],
    #    ["time_batch"],
    #    ["TIME_PERIOD", ["SECOND_PART", ["10"]]]]],
    #  ["WHERE_EXPR",
    #   ["EVAL_AND_EXPR",
    #    [">",
    #     ["cast",
    #      ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", ["amount"]]],
    #      ["double"]],
    #     ["2"]],
    #    [">", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", ["price"]]], ["50"]]]]]
  end
end
