module Norikra
  class Query
    ### SELECT MAX(size) AS maxsize, fraud.aaa,bbb
    ### FROM FraudWarningEvent.win:keepall() AS fraud,
    ###      PINChangeEvent(size > 10).win:time(20 sec)
    ### WHERE fraud.accountNumber.substr(0,8) = substr(PINChangeEvent.accountNumber, 0, 8)
    ###   AND cast(PINChangeEvent.size,double) > 10.5
    #
    # ["EPL_EXPR",
    #  ["SELECTION_EXPR",
    #   ["SELECTION_ELEMENT_EXPR",
    #    ["LIB_FUNC_CHAIN",
    #     ["LIB_FUNCTION",
    #      "max",
    #      ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "size"]],
    #      "("]],
    #    "maxsize"],
    #   ["SELECTION_ELEMENT_EXPR",
    #    ["EVENT_PROP_EXPR",
    #     ["EVENT_PROP_SIMPLE", "fraud"],
    #     ["EVENT_PROP_SIMPLE", "aaa"]]],
    #   ["SELECTION_ELEMENT_EXPR",
    #    ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "bbb"]]]],
    #  ["STREAM_EXPR",
    #   ["EVENT_FILTER_EXPR", "FraudWarningEvent"],
    #   ["VIEW_EXPR", "win", "keepall"],
    #   "fraud"],
    #  ["STREAM_EXPR",
    #   ["EVENT_FILTER_EXPR",
    #    "PINChangeEvent",
    #    [">", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "size"]], "10"]],
    #   ["VIEW_EXPR", "win", "time", ["TIME_PERIOD", ["SECOND_PART", "20"]]]],
    #  ["WHERE_EXPR",
    #   ["EVAL_AND_EXPR",
    #    ["EVAL_EQUALS_EXPR",
    #     ["LIB_FUNC_CHAIN",
    #      ["LIB_FUNCTION", "fraud.accountNumber", "substr", "0", "8", "("]],
    #     ["LIB_FUNC_CHAIN",
    #      ["LIB_FUNCTION",
    #       "substr",
    #       ["EVENT_PROP_EXPR",
    #        ["EVENT_PROP_SIMPLE", "PINChangeEvent"],
    #        ["EVENT_PROP_SIMPLE", "accountNumber"]],
    #       "0",
    #       "8",
    #       "("]]],
    #    [">",
    #     ["cast",
    #      ["EVENT_PROP_EXPR",
    #       ["EVENT_PROP_SIMPLE", "PINChangeEvent"],
    #       ["EVENT_PROP_SIMPLE", "size"]],
    #      "double"],
    #     "10.5"]]]]

    def astnode(tree)
      children = if tree.children
                   tree.children.map{|c| astnode(c)}
                 else
                   []
                 end
      case tree.text
      when 'EVENT_PROP_EXPR'
        ASTEventPropNode.new(tree.text, children)
      when 'LIB_FUNCTION'
        ASTLibFunctionNode.new(tree.text, children)
      when 'STREAM_EXPR'
        ASTStreamNode.new(tree.text, children)
      when 'SUBSELECT_EXPR'
        ASTSubSelectNode.new(tree.text, children)
      else
        ASTNode.new(tree.text, children)
      end
    end

    class ASTNode
      attr_accessor :name, :children

      def initialize(name, children)
        @name = name
        @children = children
      end

      def nodetype?(*sym)
        false
      end

      def to_a
        [@name] + @children.map{|c| c.children.size > 0 ? c.to_a : c.name}
      end

      def child
        @children.first
      end

      def find(type) # only one, depth-first search
        return self if type.is_a?(String) && @name == type || nodetype?(type)

        @children.each do |c|
          next if type != :subquery && c.nodetype?(:subquery)
          r = c.find(type)
          return r if r
        end
        nil
      end

      def listup(type) # search all nodes that has 'type'
        result = []
        result.push(self) if type.is_a?(String) && @name == type || nodetype?(type)

        @children.each do |c|
          next if type != :subquery && c.nodetype?(:subquery)
          result.push(*c.listup(type))
        end
        result
      end

      def fields(default_target=nil)
        @children.map{|c| c.nodetype?(:subquery) ? [] : c.fields(default_target)}.reduce(&:+) || []
      end
    end

    class ASTEventPropNode < ASTNode # EVENT_PROP_EXPR
      # ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "bbb"]]
      # ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "fraud"], ["EVENT_PROP_SIMPLE", "aaa"]]

      def nodetype?(*sym)
        sym.include?(:prop) || sym.include?(:property)
      end

      def fields(default_target=nil)
        props = self.listup('EVENT_PROP_SIMPLE')
        if props.size > 1 # alias.fieldname
          [ {:f => props[1].child.name, :t => props[0].child.name} ]
        else # fieldname (default target)
          [ {:f => props[0].child.name, :t => default_target } ]
        end
      end
    end

    class ASTLibFunctionNode < ASTNode # LIB_FUNCTION
      # ["LIB_FUNCTION", "now", "("]                 #### now()
      # ["LIB_FUNCTION", "hoge", "length", "("] #    #### hoge.length()
      # ["LIB_FUNCTION", "hoge", "substr", "0", "("] #### hoge.substr(0)
      # ["LIB_FUNCTION", "substr", "10", "0", "("]   #### substr(10,0)
      # ["LIB_FUNCTION", "hoge", "substr", "0", "8", "("] #### hoge.substr(0,8)
      # ["LIB_FUNCTION", "max", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "size"]], "("] #### max(size)

      def nodetype?(*sym)
        sym.include?(:lib) || sym.include?(:libfunc)
      end

      def fields(default_target=nil)
        if @children.size <= 2
          # single function like 'now()', function-name and "("
          []

        elsif @children[1].nodetype?(:prop, :lib, :subquery)
          # first element should be func name if second element is property, library call or subqueries
          self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target)}.reduce(&:+) || []

        elsif @children[1].name =~ /^(-)?\d+(\.\d+)$/ || @children[1].name =~ /^'[^']*'$/ || @children[1].name =~ /^"[^"]*"$/
          # first element should be func name if secod element is number/string literal
          self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target)}.reduce(&:+) || []

        elsif Norikra::Query.imported_java_class?(@children[0].name)
          # Java imported class name (ex: 'Math.abs(-1)')
          self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target)}.reduce(&:+) || []

        else
          # first element may be property (simple 'fieldname.funcname()' or fully qualified 'target.fieldname.funcname()')
          target,fieldname = if @children[0].name.include?('.')
                               @children[0].name.split('.', 2)
                             else
                               [default_target,@children[0].name]
                             end
          children_list = self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target)}.reduce(&:+) || []
          [{:f => fieldname, :t => target}] + children_list
        end
      end
    end

    class ASTStreamNode < ASTNode # STREAM_EXPR
      #  ["STREAM_EXPR",
      #   ["EVENT_FILTER_EXPR", "FraudWarningEvent"],
      #   ["VIEW_EXPR", "win", "keepall"],
      #   "fraud"],
      #  ["STREAM_EXPR",
      #   ["EVENT_FILTER_EXPR",
      #    "PINChangeEvent",
      #    [">", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "size"]], "10"]],
      #   ["VIEW_EXPR", "win", "time", ["TIME_PERIOD", ["SECOND_PART", "20"]]]],

      def nodetype?(*sym)
        sym.include?(:stream)
      end

      def target
        self.find('EVENT_FILTER_EXPR').child.name
      end

      def alias
        @children.last.children.size < 1 ? @children.last.name : nil
      end

      def fields(default_target=nil)
        this_target = self.target
        self.listup('EVENT_PROP_EXPR').map{|p| p.fields(this_target)}.reduce(&:+) || []
      end
    end

    class ASTSubSelectNode < ASTNode # SUBSELECT_EXPR
      def nodetype?(*sym)
        sym.include?(:subquery)
      end
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
  end
end
