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

    ### SELECT count(*) AS cnt
    ### FROM TestTable.win:time_batch(10 sec)
    ### WHERE params.$$path.$1="/" AND size.$0.bytes > 100 and opts.num.seq.length() > 0

    # ["EPL_EXPR",
    #  ["SELECTION_EXPR", ["SELECTION_ELEMENT_EXPR", "count", "cnt"]],
    #  ["STREAM_EXPR",
    #   ["EVENT_FILTER_EXPR", "TestTable"],
    #   ["VIEW_EXPR", "win", "time_batch", ["TIME_PERIOD", ["SECOND_PART", "10"]]]],
    #  ["WHERE_EXPR",
    #   ["EVAL_AND_EXPR",
    #    ["EVAL_EQUALS_EXPR",
    #     ["EVENT_PROP_EXPR",
    #      ["EVENT_PROP_SIMPLE", "params"],
    #      ["EVENT_PROP_SIMPLE", "$$path"],
    #      ["EVENT_PROP_SIMPLE", "$1"]],
    #     "\"/\""],
    #    [">",
    #     ["EVENT_PROP_EXPR",
    #      ["EVENT_PROP_SIMPLE", "size"],
    #      ["EVENT_PROP_SIMPLE", "$0"],
    #      ["EVENT_PROP_SIMPLE", "bytes"]],
    #     "100"],
    #    [">",
    #     ["LIB_FUNC_CHAIN", ["LIB_FUNCTION", "opts.num.seq", "length", "("]],
    #     "0"]]]]

    ### SELECT a.name, a.content, b.content
    ### FROM pattern[every a=EventA -> b=EventA(name = a.name, type = 'TYPE') WHERE timer:within(1 min)].win:time(2 hour)
    ### WHERE a.source in ('A', 'B')

    # ["EPL_EXPR",
    #   ["SELECTION_EXPR",
    #     ["SELECTION_ELEMENT_EXPR",
    #       ["EVENT_PROP_EXPR",
    #         ["EVENT_PROP_SIMPLE", "a"],
    #         ["EVENT_PROP_SIMPLE", "name"]]],
    #     ["SELECTION_ELEMENT_EXPR",
    #       ["EVENT_PROP_EXPR",
    #         ["EVENT_PROP_SIMPLE", "a"],
    #         ["EVENT_PROP_SIMPLE", "content"]]],
    #     ["SELECTION_ELEMENT_EXPR",
    #       ["EVENT_PROP_EXPR",
    #         ["EVENT_PROP_SIMPLE", "b"],
    #         ["EVENT_PROP_SIMPLE", "content"]]]],
    #   ["STREAM_EXPR",
    #     ["PATTERN_INCL_EXPR",
    #       ["FOLLOWED_BY_EXPR",
    #         ["FOLLOWED_BY_ITEM", ["every", ["PATTERN_FILTER_EXPR", "a", "EventA"]]],
    #         ["FOLLOWED_BY_ITEM",
    #           ["GUARD_EXPR",
    #             ["PATTERN_FILTER_EXPR",
    #               "b",
    #               "EventA",
    #               ["EVAL_EQUALS_EXPR",
    #                 ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "name"]],
    #                 ["EVENT_PROP_EXPR",
    #                   ["EVENT_PROP_SIMPLE", "a"],
    #                   ["EVENT_PROP_SIMPLE", "name"]]],
    #               ["EVAL_EQUALS_EXPR",
    #                 ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "type"]],
    #                 "'TYPE'"]],
    #             "timer",
    #             "within",
    #             ["TIME_PERIOD", ["MINUTE_PART", "1"]]]]]],
    #     ["VIEW_EXPR", "win", "time", ["TIME_PERIOD", ["HOUR_PART", "2"]]]],
    #   ["WHERE_EXPR",
    #     ["in",
    #       ["EVENT_PROP_EXPR",
    #         ["EVENT_PROP_SIMPLE", "a"],
    #         ["EVENT_PROP_SIMPLE", "source"]],
    #       "(",
    #       "'A'",
    #       "'B'",
    #       ")"]]]

    def astnode(tree)
      children = if tree.children
                   tree.children.map{|c| astnode(c)}
                 else
                   []
                 end
      cls = case tree.text
            when 'EVENT_PROP_EXPR' then ASTEventPropNode
            when 'SELECTION_ELEMENT_EXPR' then ASTSelectionElementNode
            when 'LIB_FUNCTION' then ASTLibFunctionNode
            when 'STREAM_EXPR' then ASTStreamNode
            when 'PATTERN_FILTER_EXPR' then ASTPatternNode
            when 'SUBSELECT_EXPR' then ASTSubSelectNode
            else ASTNode
            end
      if cls.respond_to?(:generate)
        cls.generate(tree.text, children, tree)
      else
        cls.new(tree.text, children, tree)
      end
    end

    class ASTNode
      attr_accessor :name, :children, :tree

      def initialize(name, children, tree)
        @name = name
        @children = children
        @tree = tree
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

      def listup(*type) # search all nodes that has 'type'
        if type.size > 1
          return type.map{|t| self.listup(t) }.reduce(&:+)
        end
        type = type.first

        result = []
        result.push(self) if type.is_a?(String) && @name == type || nodetype?(type)

        @children.each do |c|
          next if type != :subquery && c.nodetype?(:subquery)
          result.push(*c.listup(type))
        end
        result
      end

      def fields(default_target=nil, known_targets_aliases=[])
        @children.map{|c| c.nodetype?(:subquery) ? [] : c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
      end
    end

    class ASTEventPropNode < ASTNode # EVENT_PROP_EXPR
      # "bbb"           => ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "bbb"]]
      # "fraud.aaa"     => ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "fraud"], ["EVENT_PROP_SIMPLE", "aaa"]]
      # "size.$0.bytes" => ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "size"],  ["EVENT_PROP_SIMPLE", "$0"], ["EVENT_PROP_SIMPLE", "bytes"]]

      def nodetype?(*sym)
        sym.include?(:prop) || sym.include?(:property)
      end

      def fields(default_target=nil, known_targets_aliases=[])
        props = self.listup('EVENT_PROP_SIMPLE')
        if props.size > 1 # alias.fieldname or container_fieldname.key.$1
          if known_targets_aliases.include?(props[0].child.name)
            [ {:f => props[1..-1].map{|n| n.child.name}.join("."), :t => props[0].child.name} ]
          else
            [ {:f => props.map{|n| n.child.name}.join("."), :t => default_target} ]
          end
        else # fieldname (default target)
          [ {:f => props[0].child.name, :t => default_target } ]
        end
      end
    end

    class ASTSelectionElementNode < ASTNode # SELECTION_ELEMENT_EXPR
      # "count(*) AS cnt"  => ["SELECTION_ELEMENT_EXPR", "count", "cnt"]
      # "n.s as s"         => ["SELECTION_ELEMENT_EXPR", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "n"], ["EVENT_PROP_SIMPLE", "s"]], "s"]
      def nodetype?(*sym)
        sym.include?(:selection)
      end

      def alias
        @children.size == 2 ? @children[1].name : nil
      end
    end

    class ASTLibFunctionNode < ASTNode # LIB_FUNCTION
      ### foo is function
      # "foo()"     => ["LIB_FUNCTION", "foo", "("]
      # "foo(10)"   => ["LIB_FUNCTION", "foo", "10", "("]
      # "foo(10,0)" => ["LIB_FUNCTION", "foo", "10", "0", "("]
      # "foo(bar)"  => ["LIB_FUNCTION", "foo", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "bar"]], "("]

      ### foo is property
      # "foo.bar()"    => ["LIB_FUNCTION", "foo", "bar", "("]
      # "foo.bar(0)"   => ["LIB_FUNCTION", "foo", "bar", "0", "("]
      # "foo.bar(0,8)" => ["LIB_FUNCTION", "foo", "bar", "0", "8", "("]

      ### nested field access
      # "foo.bar.$0.baz()" => ["LIB_FUNCTION", "foo.bar.$0", "baz", "("]

      # 2nd child is bare-word (like [a-z][a-z0-9]*) -> this is function -> 1st child is receiver -> property
      # 2nd child is literal or property or none -> 1st child is built-in function

      def nodetype?(*sym)
        sym.include?(:lib) || sym.include?(:libfunc)
      end

      def fields(default_target=nil, known_targets_aliases=[])
        if @children.size <= 2
          # single function like 'now()', function-name and "("
          []

        elsif @children[1].nodetype?(:prop, :lib, :subquery)
          # first element should be func name if second element is property, library call or subqueries
          self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []

        elsif @children[1].name =~ /^(-)?\d+(\.\d+)?$/ || @children[1].name =~ /^'[^']*'$/ || @children[1].name =~ /^"[^"]*"$/
          # first element should be func name if secod element is number/string literal
          self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []

        elsif Norikra::Query.imported_java_class?(@children[0].name)
          # Java imported class name (ex: 'Math.abs(-1)')
          self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []

        else
          # first element may be property ########## or function
          #  * simple 'fieldname.funcname()'
          #  * fully qualified 'target.fieldname.funcname()'
          #  * simple/fully-qualified container field access 'fieldname.key.$0.funcname()' or 'target.fieldname.$1.funcname()'
          target,fieldname = if @children[0].name.include?('.')
                               parts = @children[0].name.split('.')
                               if known_targets_aliases.include?(parts[0])
                                 [ parts[0], parts[1..-1].join(".") ]
                               else
                                 [ default_target, @children[0].name ]
                               end
                             else
                               [default_target,@children[0].name]
                             end
          children_list = self.listup('EVENT_PROP_EXPR').map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
          [{:f => fieldname, :t => target}] + children_list
        end
      end
    end

    class ASTStreamNode < ASTNode # STREAM_EXPR
      def self.generate(name, children, tree)
        if children.first.name == 'EVENT_FILTER_EXPR'
          ASTStreamEventNode.new(name, children, tree)
        elsif children.first.name == 'PATTERN_INCL_EXPR'
          ASTStreamPatternNode.new(name, children, tree)
        else
          raise "unexpected stream node type! report to norikra developer!: #{children.map(&:name).join(',')}"
        end
      end

      def nodetype?(*sym)
        sym.include?(:stream)
      end

      def targets
        # ["TARGET_NAME"]
        raise NotImplementedError, "ASTStreamNode#targets MUST be overridden by subclass"
      end

      def aliases
        # [ [ "ALIAS_NAME", "TARGET_NAME" ], ... ]
        raise NotImplementedError, "ASTStreamNode#aliases MUST be overridden by subclass"
      end

      def fields(default_target=nil, known_targets_aliases=[])
        raise NotImplementedError, "ASTStreamNode#fields MUST be overridden by subclass"
      end
    end

    class ASTStreamEventNode < ASTStreamNode
      ##### from stream_def [as name] [unidirectional] [retain-union | retain-intersection],
      #####      [ stream_def ... ]
      #
      # single Event stream name ( ex: FROM events.win:time(...) AS e )
      #
      #  ["STREAM_EXPR",
      #   ["EVENT_FILTER_EXPR", "FraudWarningEvent"],
      #   ["VIEW_EXPR", "win", "keepall"],
      #   "fraud"],
      #
      #  ["STREAM_EXPR",
      #   ["EVENT_FILTER_EXPR",
      #    "PINChangeEvent",
      #    [">", ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "size"]], "10"]],
      #   ["VIEW_EXPR", "win", "time", ["TIME_PERIOD", ["SECOND_PART", "20"]]]],

      NON_ALIAS_NODES = ['EVENT_FILTER_EXPR','VIEW_EXPR','unidirectional','retain-union','retain-intersection']

      def targets
        [self.find('EVENT_FILTER_EXPR').child.name]
      end

      def aliases
        alias_nodes = children.select{|n| not NON_ALIAS_NODES.include?(n.name) }
        if alias_nodes.size < 1
          []
        elsif alias_nodes.size > 1
          raise "unexpected FROM clause (includes 2 or more alias words): #{alias_nodes.map(&:name).join(',')}"
        else
          [ [ alias_nodes.first.name, self.targets.first ] ]
        end
      end

      def fields(default_target=nil, known_targets_aliases=[])
        this_target = self.targets.first
        self.listup('EVENT_PROP_EXPR').map{|p| p.fields(this_target,known_targets_aliases)}.reduce(&:+) || []
      end
    end

    class ASTStreamPatternNode < ASTStreamNode
      ## MEMO: Pattern itself can have alias name, but it makes no sense. So we ignore it.
      ##       ('x' is ignored): pattern [... ] AS x
      #
      # pattern ( ex: FROM pattern[ every a=events1 -> b=Events1(name=a.name, type='T') where timer:within(1 min) ].win:time(2 hour) )
      #
      # ["STREAM_EXPR",
      #   ["PATTERN_INCL_EXPR",
      #     ["FOLLOWED_BY_EXPR",
      #       ["FOLLOWED_BY_ITEM", ["every", ["PATTERN_FILTER_EXPR", "a", "EventA"]]],
      #       ["FOLLOWED_BY_ITEM",
      #         ["GUARD_EXPR",
      #           ["PATTERN_FILTER_EXPR",
      #             "b",
      #             "EventA",
      #             ["EVAL_EQUALS_EXPR",
      #               ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "name"]],
      #               ["EVENT_PROP_EXPR",
      #                 ["EVENT_PROP_SIMPLE", "a"],
      #                 ["EVENT_PROP_SIMPLE", "name"]]],
      #             ["EVAL_EQUALS_EXPR",
      #               ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "type"]],
      #               "'TYPE'"]],
      #           "timer",
      #           "within",
      #           ["TIME_PERIOD", ["MINUTE_PART", "1"]]]]]],
      #   ["VIEW_EXPR", "win", "time", ["TIME_PERIOD", ["HOUR_PART", "2"]]]],

      def targets
        self.listup(:pattern).map(&:target)
      end

      def aliases
        self.listup(:pattern).map{|p| [ p.alias, p.target ] }
      end

      def fields(default_target=nil, known_targets_aliases=[])
        self.listup(:pattern).map{|p| p.fields(default_target, known_targets_aliases) }.reduce(&:+) || []
      end
    end

    class ASTPatternNode < ASTNode
      # ["PATTERN_FILTER_EXPR", "a", "EventA"]
      #
      # ["PATTERN_FILTER_EXPR",
      #   "b",
      #   "EventA",
      #   ["EVAL_EQUALS_EXPR",
      #     ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "name"]],
      #     ["EVENT_PROP_EXPR",
      #       ["EVENT_PROP_SIMPLE", "a"],
      #       ["EVENT_PROP_SIMPLE", "name"]]],
      #   ["EVAL_EQUALS_EXPR",
      #     ["EVENT_PROP_EXPR", ["EVENT_PROP_SIMPLE", "type"]],
      #     "'TYPE'"]],

      def nodetype?(*sym)
        sym.include?(:pattern)
      end

      def target
        children[1].name
      end

      def alias
        children[0].name
      end

      def fields(default_target=nil, known_targets_aliases=[])
        this_target = self.target
        self.listup('EVENT_PROP_EXPR').map{|p| p.fields(this_target, known_targets_aliases) }.reduce(&:+) || []
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
