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
      @target = nil
      @fields = nil
    end

    def dup
      self.class.new(:name => @name, :expression => @expression.dup)
    end

    def dup_with_stream_name(actual_name)
      tablename = self.tablename
      query = self.dup
      query.expression = self.expression.gsub(/(\s[Ff][Rr][Oo][Mm]\s+)#{tablename}(\.|\s)/, '\1' + actual_name + '\2')
      if query.tablename != actual_name
        raise RuntimeError, 'failed to replace query tablename into stream name:' + self.expression
      end
      query
    end

    def to_hash
      {'name' => @name, 'expression' => @expression, 'target' => self.target}
    end

    def target
      return @target if @target
      #TODO: this code doesn't care JOINs.
      @target = self.ast.find('STREAM_EXPR').find('EVENT_FILTER_EXPR').children.first.name
      @target
    end

    def fields
      return @fields if @fields
      #TODO: this code doesn't care JOINs.

      # Norikra::Query.new(
      #   :name => 'hoge',
      #   :expression => 'select count(*) AS cnt from www.win:time_batch(10 seconds) where path="/" AND search.length() > 0').ast.to_a
      # ["EPL_EXPR",
      #  ["SELECTION_EXPR", ["SELECTION_ELEMENT_EXPR", ["count"], ["cnt"]]],
      #  ["STREAM_EXPR",
      #   ["EVENT_FILTER_EXPR", ["www"]],
      #   ["VIEW_EXPR",
      #    ["win"],
      #    ["time_batch"],
      #    ["TIME_PERIOD", ["SECOND_PART", ["10"]]]]],
      #  ["WHERE_EXPR",
      #   ["EVAL_AND_EXPR",
      #    ["EVAL_EQUALS_EXPR",
      #     ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", ["path"]]],
      #     ["\"/\""]],
      #    [">",
      #     ["LIB_FUNC_CHAIN", ["LIB_FUNCTION", ["search"], ["length"], ["("]]],
      #     ["0"]]]]]

      ast = self.ast
      names_simple = ast.listup('EVENT_PROP_SIMPLE').map{|p| p.child.name}
      names_chain_root = ast.listup('LIB_FUNC_CHAIN').map{|c| c.child.child.name}.select{|n| not self.class.imported_java_class?(n)}
      @fields = (names_simple + names_chain_root).uniq.sort
      @fields
    end

    def self.imported_java_class?(name)
      return false unless name =~ /^[A-Z]/
      # Esper auto-imports the following Java library packages:
      # java.lang.* -> Java::JavaLang::*
      # java.math.* -> Java::JavaMath::*
      # java.text.* -> Java::JavaText::*
      # java.util.* -> Java::JavaUtil::*
      java_class('Java::JavaLang::'+name) || java_class('Java::JavaMath::'+name) ||
        java_class('Java::JavaText::'+name) || java_class('Java::JavaUtil::'+name) || false
    end
    def self.java_class(const_name)
      begin
        c = eval(const_name)
        c.class == Kernel ? nil : c
      rescue NameError
        return nil
      end
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
      def child
        @children.first
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
      #TODO: test
      #TODO: take care for parse error
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
