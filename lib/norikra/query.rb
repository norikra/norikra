require 'java'
require 'esper-4.9.0.jar'
require 'esper/lib/commons-logging-1.1.1.jar'
require 'esper/lib/antlr-runtime-3.2.jar'
require 'esper/lib/cglib-nodep-2.2.jar'

require 'norikra/query/ast'

module Norikra
  class Query
    attr_accessor :name, :expression

    def initialize(param={})
      @name = param[:name]
      @expression = param[:expression]
      @ast = nil
      @targets = nil
      @subqueries = nil
      @fields = nil
    end

    def dup
      self.class.new(:name => @name, :expression => @expression.dup)
    end

    def dup_with_stream_name(actual_name)
      first_target = self.targets.first
      query = self.dup
      query.expression = self.expression.gsub(/(\s[Ff][Rr][Oo][Mm]\s+)#{first_target}(\.|\s)/, '\1' + actual_name + '\2')
      if query.targets.first != actual_name
        raise RuntimeError, 'failed to replace query target into stream name:' + self.expression
      end
      query
    end

    def to_hash
      {'name' => @name, 'expression' => @expression, 'targets' => self.targets}
    end

    def targets
      return @targets if @targets
      @targets = (self.ast.listup(:stream).map(&:target) + self.subqueries.map(&:targets).flatten).sort.uniq
      @targets
    end

    def subqueries
      return @subqueries if @subqueries
      @subqueries = self.ast.listup(:subquery).map{|n| Norikra::SubQuery.new(n)}
      @subqueries
    end

    def explore(outer_targets=[], alias_overridden={})
      fields = {}
      alias_map = {}.merge(alias_overridden)

      all = []
      unknowns = []
      self.ast.listup(:stream).each do |node|
        #TODO: raise error for same name of target/alias
        if node.alias
          alias_map[node.alias] = node.target
        end
        fields[node.target] = []
      end

      default_target = fields.keys.size == 1 ? fields.keys.first : nil

      outer_targets.each do |t|
        fields[t] ||= []
      end

      field_bag = []
      self.subqueries.each do |subquery|
        field_bag.push(subquery.explore(fields.keys, alias_map))
      end

      self.ast.fields(default_target).each do |field_def|
        f = field_def[:f]
        all.push(f)

        if field_def[:t]
          t = alias_map[field_def[:t]] || field_def[:t]
          unless fields[t]
            raise "unknown target alias name for: #{field_def[:t]}.#{field_def[:f]}"
          end
          fields[t].push(f)

        else
          unknowns.push(f)
        end
      end

      field_bag.each do |bag|
        all += bag['']
        unknowns += bag[nil]
        bag.keys.each do |t|
          fields[t] ||= []
          fields[t] += bag[t]
        end
      end

      fields.keys.each do |target|
        fields[target] = fields[target].sort.uniq
      end
      fields[''] = all.sort.uniq
      fields[nil] = unknowns.sort.uniq

      fields
    end

    def fields(target='')
      # target '': fields for all targets (without target name)
      # target nil: fields for unknown targets
      return @fields[target] if @fields

      @fields = explore()
      @fields[target]
    end

    class ParseRuleSelectorImpl
      include com.espertech.esper.epl.parse.ParseRuleSelector
      def invokeParseRule(parser)
        parser.startEPLExpressionRule().getTree()
      end
    end

    def ast
      #TODO: take care for parse error(com.espertech.esper.client.EPStatementSyntaxException)
      return @ast if @ast
      rule = ParseRuleSelectorImpl.new
      target = @expression.dup
      forerrmsg = @expression.dup
      result = com.espertech.esper.epl.parse.ParseHelper.parse(target, forerrmsg, true, rule, false)

      @ast = astnode(result.getTree)
      @ast
    end

    def self.rewrite_event_type_name(statement_model, mapping)
      # mapping: {target_name => query_event_type_name}

      ### esper-4.9.0/esper/doc/reference/html/epl_clauses.html#epl-subqueries
      # Subqueries can only consist of a select clause, a from clause and a where clause.
      # The group by and having clauses, as well as joins, outer-joins and output rate limiting are not permitted within subqueries.

      # model.getFromClause.getStreams[0].getFilter.setEventTypeName("hoge")

      # model.getSelectClause.getSelectList[1].getExpression => #<Java::ComEspertechEsperClientSoda::SubqueryExpression:0x3344c133>
      # model.getSelectClause.getSelectList[1].getExpression.getModel.getFromClause.getStreams[0].getFilter.getEventTypeName
      # model.getWhereClause.getChildren[1]                 .getModel.getFromClause.getStreams[0].getFilter.getEventTypeName

      statement_model.getFromClause.getStreams.each do |stream|
        target_name = stream.getFilter.getEventTypeName
        unless mapping[target_name]
          raise RuntimeError, "target missing in mapping, maybe BUG"
        end
        stream.getFilter.setEventTypeName(mapping[target_name])
      end

      dig = lambda {|node|
        if node.is_a?(Java::ComEspertechEsperClientSoda::SubqueryExpression)
          Norikra::Query.rewrite_event_type_name(node.getModel, mapping)
        elsif node.getChildren.size > 0
          node.getChildren.each do |c|
            dig.call(c)
          end
        end
      }

      if statement_model.getSelectClause
        statement_model.getSelectClause.getSelectList.each do |item|
          dig.call(item.getExpression)
        end
      end

      if statement_model.getWhereClause
        statement_model.getWhereClause.getChildren.each do |child|
          dig.call(child)
        end
      end

      statement_model
    end
  end

  class SubQuery < Query
    def initialize(ast_nodetree)
      @ast = ast_nodetree
      @targets = nil
      @subqueries = nil
    end

    def ast; @ast; end

    def subqueries
      return @subqueries if @subqueries
      @subqueries = @ast.children.map{|c| c.listup(:subquery)}.reduce(&:+).map{|n| Norikra::SubQuery.new(n)}
      @subqueries
    end

    def name; ''; end
    def expression; ''; end
    def dup; self; end
    def dup_with_stream_name(actual_name); self; end
  end
end
