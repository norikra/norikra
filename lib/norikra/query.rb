require 'java'
require 'esper-5.0.0.jar'
require 'esper/lib/commons-logging-1.1.3.jar'
require 'esper/lib/antlr-runtime-4.1.jar'
require 'esper/lib/cglib-nodep-3.1.jar'

require 'norikra/error'
require 'norikra/query/ast'
require 'norikra/field'

module Norikra
  class Query
    attr_accessor :name, :group, :expression, :statement_name, :fieldsets

    def initialize(param={})
      @name = param[:name]
      raise Norikra::ArgumentError, "Query name MUST NOT be blank" if @name.nil? || @name.empty?
      @group = param[:group] # default nil
      #TODO: ad-hoc query rewriting for https://jira.codehaus.org/browse/ESPER-788
      @expression = param[:expression].gsub(/([ ,])(MIN|MAX)\(/){ $1 + $2.downcase + '(' }
      raise Norikra::ArgumentError, "Query expression MUST NOT be blank" if @expression.nil? || @expression.empty?

      @statement_name = nil
      @fieldsets = {} # { target => fieldset }
      @ast = nil
      @targets = nil
      @aliases = nil
      @subqueries = nil
      @fields = nil
      @nullable_fields = nil
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

    def self.loopback(group)
      group && group =~ /^LOOPBACK\((.+)\)$/ && $1
    end

    def self.stdout?(group)
      group && group == "STDOUT()"
    end

    def dup
      self.class.new(:name => @name, :group => @group, :expression => @expression.dup)
    end

    def to_hash
      {'name' => @name, 'group' => @group, 'expression' => @expression, 'targets' => self.targets, 'suspended' => false}
    end

    def dump
      {name: @name, group: @group, expression: @expression}
    end

    def suspended?
      false
    end

    def invalid?
      # check query is invalid as Norikra query or not
      self.ast.listup('selectionListElement').any?{|node| node.children.map(&:name).any?{|name| name == '*' } }

      ### TODO: check arg of nullable(...) is just 'a' simple property reference
    end

    def targets
      return @targets if @targets
      @targets = (self.ast.listup(:stream).map(&:targets).flatten + self.subqueries.map(&:targets).flatten).sort.uniq
      @targets
    end

    def aliases
      return @aliases if @aliases
      @aliases = (self.ast.listup(:stream).map{|s| s.aliases.map(&:first) }.flatten + self.subqueries.map(&:aliases).flatten).sort.uniq
      @aliases
    end

    def subqueries
      return @subqueries if @subqueries
      @subqueries = self.ast.listup(:subquery).map{|n| Norikra::SubQuery.new(n)}
      @subqueries
    end

    def explore(outer_targets=[], alias_overridden={})
      ### TODO: nullable_fields

      fields = {
        defs: { all: [], unknown: [], target: {} },
        nullables: { all: [], unknown: [], target: {} },
      }

      alias_map = alias_overridden.dup

      self.ast.listup(:stream).each do |node|
        node.aliases.each do |alias_name, target|
          alias_map[alias_name] = target
        end
        node.targets.each do |target|
          fields[:defs][:target][target] = []
          fields[:nullables][:target][target] = []
        end
      end

      # default target should be out of effect of outer_targets
      default_target = fields[:defs][:target].keys.size == 1 ? fields[:defs][:target].keys.first : nil

      outer_targets.each do |t|
        fields[:defs][:target][t] ||= []
        fields[:nullables][:target][t] ||= []
      end

      dup_aliases = (alias_map.keys & fields[:defs][:target].keys)
      unless dup_aliases.empty?
        raise Norikra::ClientError, "Invalid alias '#{dup_aliases.join(',')}', same with target name"
      end

      # names of 'AS'
      field_aliases = self.ast.listup(:selection).map(&:alias).compact

      known_targets_aliases = fields[:defs][:target].keys + alias_map.keys
      self.ast.fields(default_target, known_targets_aliases).each do |field_def|
        f = field_def[:f]
        next if field_aliases.include?(f)

        fields[:defs][:all].push(f)
        fields[:nullables][:all].push(f) if field_def[:n]

        if field_def[:t]
          t = alias_map[field_def[:t]] || field_def[:t]
          unless fields[:defs][:target][t]
            raise Norikra::ClientError, "unknown target alias name for: #{field_def[:t]}.#{field_def[:f]}"
          end
          fields[:defs][:target][t].push(f)
          fields[:nullables][:target][t].push(f) if field_def[:n]
        else
          fields[:defs][:unknown].push(f)
          fields[:nullables][:unknown].push(f) if field_def[:n]
        end
      end

      self.subqueries.each do |subquery|
        sub = {}
        sub[:defs], sub[:nullables] = subquery.explore(fields[:defs][:target].keys, alias_map)

        [:defs, :nullables].each do |group|
          fields[group][:all] += sub[group].delete('')
          fields[group][:unknown] += sub[group].delete(nil)
          sub[group].keys.each do |t|
            fields[group][:target][t] ||= []
            fields[group][:target][t] += sub[group][t]
          end
        end
      end

      compact = ->(data){
        r = {}
        data[:target].keys.each do |t|
          r[t] = data[:target][t].sort.uniq
        end
        r[''] = data[:all].sort.uniq
        r[nil] = data[:unknown].sort.uniq
        r
      }

      [ compact.(fields[:defs]), compact.(fields[:nullables]) ]
    end

    def fields(target='')
      # target '': fields for all targets (without target name)
      # target nil: fields for unknown targets
      return @fields[target] if @fields

      @fields, @nullable_fields = explore()
      @fields[target]
    end

    def nullable_fields(target='')
      # argument target is same with #fields
      return @nullable_fields[target] if @nullable_fields

      @fields, @nullable_fields = explore()
      @nullable_fields[target]
    end

    class ParseRuleSelectorImpl
      include Java::ComEspertechEsperEplParse::ParseRuleSelector
      def invokeParseRule(parser)
        parser.startEPLExpressionRule()
      end
    end

    def ast
      return @ast if @ast
      rule = ParseRuleSelectorImpl.new
      target = @expression.dup
      forerrmsg = @expression.dup
      result = Java::ComEspertechEsperEplParse::ParseHelper.parse(target, forerrmsg, true, rule, false)

      # walk through AST and check syntax errors/semantic errors
      ast = result.tree

      services = Java::ComEspertechEsperClient::EPServiceProviderManager.getDefaultProvider.getServicesContext

      walker = Java::ComEspertechEsperEplParse::EPLTreeWalkerListener.new(
        result.getTokenStream,
        services.getEngineImportService,
        services.getVariableService,
        services.getSchedulingService,
        Java::ComEspertechEsperEplSpec::SelectClauseStreamSelectorEnum.mapFromSODA(
          services.getConfigSnapshot.getEngineDefaults.getStreamSelection.getDefaultStreamSelector
        ),
        services.getEngineURI,
        services.getConfigSnapshot,
        services.getPatternNodeFactory,
        services.getContextManagementService,
        result.getScripts,
        services.getExprDeclaredService
      )

      Java::ComEspertechEsperEplParse::ParseHelper.walk(ast, walker, target, forerrmsg)

      @ast = astnode(ast)
      @ast
    rescue Java::ComEspertechEsperEplParse::ASTWalkException => e
      raise Norikra::QueryError, e.message
    rescue Java::ComEspertechEsperClient::EPStatementSyntaxException => e
      raise Norikra::QueryError, e.message
    end

    def self.rewrite_query(statement_model, mapping)
      ### TODO: rewrite_nullable_fields
      rewrite_event_type_name(statement_model, mapping)
      rewrite_event_field_name(statement_model, mapping)
    end

    def self.rewrite_event_field_name(statement_model, mapping)
      # mapping: {target_name => query_event_type_name}
      #  mapping is for target name rewriting of fully qualified field name access


      # model.getFromClause.getStreams[0].getViews[0].getParameters[0].getPropertyName

      # model.getSelectClause.getSelectList[0].getExpression.getPropertyName
      # model.getSelectClause.getSelectList[0].getExpression.getChildren[0].getPropertyName #=> 'field.key1.$0'

      # model.getWhereClause.getChildren[1].getChildren[0].getPropertyName #=> 'field.key1.$1'
      # model.getWhereClause.getChildren[2].getChildren[0].getChain[0].getName #=> 'opts.num.$0' from opts.num.$0.length()

      query = Norikra::Query.new(:name => 'dummy name by .rewrite_event_field_name', :expression => statement_model.toEPL)
      targets = query.targets
      fqfs_prefixes = targets + query.aliases

      default_target = (targets.size == 1 ? targets.first : nil)

      rewrite_name = lambda {|node,getter,setter|
        name = node.send(getter)
        if name && name.index('.')
          prefix = nil
          body = nil
          first_part = name.split('.').first
          if fqfs_prefixes.include?(first_part) or mapping.has_key?(first_part) # fully qualified field specification
            prefix = first_part
            if mapping[prefix]
              prefix = mapping[prefix]
            end
            body = name.split('.')[1..-1].join('.')
          elsif default_target # default target field (outside of join context)
            body = name
          else
            raise Norikra::QueryError, "target cannot be determined for field '#{name}'"
          end
          #### 'field.javaMethod("args")' MUST NOT be escaped....
          # 'getPropertyName' returns a String "path.index(\".\")" for java method calling,
          #  and other optional informations are not provided.
          # We seems that '.camelCase(ANYTHING)' should be a method calling, not nested field accesses.
          # This is ugly, but works.
          #
          # 'path.substring(0, path.indexOf(path.substring(1,1)))' is parsed as 3-times-nested LIB_FUNCTION_CHAIN,
          #  so does not make errors.
          #
          method_chains = []
          body_chains = body.split('.')
          while body_chains.size > 0
            break unless body_chains.last =~ /^[a-z][a-zA-Z]*\(.*\)$/
            method_chains.unshift body_chains.pop
          end

          escaped_body = Norikra::Field.escape_name(body_chains.join('.'))
          encoded = (prefix ? "#{prefix}." : "") + escaped_body + (method_chains.size > 0 ? '.' + method_chains.join('.') : '' )
          node.send(setter, encoded)
        end
      }

      rewriter = lambda {|node|
        if node.respond_to?(:getPropertyName)
          rewrite_name.call(node, :getPropertyName, :setPropertyName)
        elsif node.respond_to?(:getChain)
          node.getChain.each do |chain|
            rewrite_name.call(chain, :getName, :setName)
          end
        end
      }
      recaller = lambda {|node|
        Norikra::Query.rewrite_event_field_name(node.getModel, mapping)
      }

      traverse_fields(rewriter, recaller, statement_model)
    end

    def self.rewrite_event_type_name(statement_model, mapping)
      # mapping: {target_name => query_event_type_name}

      ### esper-4.9.0/esper/doc/reference/html/epl_clauses.html#epl-subqueries
      # Subqueries can only consist of a select clause, a from clause and a where clause.
      # The group by and having clauses, as well as joins, outer-joins and output rate limiting are not permitted within subqueries.

      # model.getFromClause.getStreams[0].getFilter.setEventTypeName("hoge") # normal Stream
      # model.getFromClause.getStreams[1].getExpression.getChildren[0].getChildren[0].getFilter.getEventTypeName # pattern

      # model.getSelectClause.getSelectList[1].getExpression => #<Java::ComEspertechEsperClientSoda::SubqueryExpression:0x3344c133>
      # model.getSelectClause.getSelectList[1].getExpression.getModel.getFromClause.getStreams[0].getFilter.getEventTypeName
      # model.getWhereClause.getChildren[1]                 .getModel.getFromClause.getStreams[0].getFilter.getEventTypeName

      rewriter = lambda {|node|
        if node.respond_to?(:getEventTypeName)
          target_name = node.getEventTypeName
          rewrite_name = mapping[ target_name ]
          unless rewrite_name
            raise RuntimeError, "target missing in mapping, maybe BUG: #{target_name}"
          end
          node.setEventTypeName(rewrite_name)
        end
      }
      recaller = lambda {|node|
        Norikra::Query.rewrite_event_type_name(node.getModel, mapping)
      }
      traverse_fields(rewriter, recaller, statement_model)
    end

    ### Targets and fields re-writing supports (*) nodes
    # model.methods.select{|m| m.to_s.start_with?('get') && !m.to_s.start_with?('get_')}.sort

    # :getAnnotations,
    # :getClass,
    # :getContextName,
    # :getCreateContext,
    # :getCreateDataFlow,
    # :getCreateExpression,
    # :getCreateIndex,
    # :getCreateSchema,
    # :getCreateVariable,
    # :getCreateWindow,
    # :getExpressionDeclarations,
    # :getFireAndForgetClause,
    # :getForClause,
    # (*) :getFromClause,
    # (*) :getGroupByClause,
    # (*) :getHavingClause,
    # :getInsertInto,
    # :getMatchRecognizeClause,
    # :getOnExpr,
    # (*) :getOrderByClause,
    # :getOutputLimitClause,
    # :getRowLimitClause,
    # :getScriptExpressions,
    # (*) :getSelectClause,
    # :getTreeObjectName,
    # :getUpdateClause,
    # (*) :getWhereClause,

    def self.traverse_fields(rewriter, recaller, statement_model)
      #NOTICE: SQLStream is not supported yet.
      dig = lambda {|node|
        return unless node
        rewriter.call(node)

        if node.is_a?(Java::ComEspertechEsperClientSoda::SubqueryExpression)
          recaller.call(node)
        end
        if node.respond_to?(:getFilter)
          dig.call(node.getFilter)
        end
        if node.respond_to?(:getChildren)
          node.getChildren.each do |c|
            dig.call(c)
          end
        end
        if node.respond_to?(:getParameters)
          node.getParameters.each do |p|
            dig.call(p)
          end
        end
        if node.respond_to?(:getChain)
          node.getChain.each do |c|
            dig.call(c)
          end
        end
        if node.respond_to?(:getExpression)
          dig.call(node.getExpression)
        end
        if node.respond_to?(:getExpressions)
          node.getExpressions.each do |e|
            dig.call(e)
          end
        end
      }

      statement_model.getFromClause.getStreams.each do |stream|
        if stream.respond_to?(:getExpression) # PatternStream < ProjectedStream
          dig.call(stream.getExpression)
        end
        if stream.respond_to?(:getFilter) # Filter < ProjectedStream
          dig.call(stream.getFilter)
        end
        if stream.respond_to?(:getParameterExpressions) # MethodInvocationStream
          dig.call(stream.getParameterExpressions)
        end
        if stream.respond_to?(:getViews) # ProjectedStream
          stream.getViews.each do |view|
            view.getParameters.each do |parameter|
              dig.call(parameter)
            end
          end
        end
      end

      if statement_model.getSelectClause
        statement_model.getSelectClause.getSelectList.each do |item|
          dig.call(item)
        end
      end

      if statement_model.getWhereClause
        statement_model.getWhereClause.getChildren.each do |child|
          dig.call(child)
        end
      end

      if statement_model.getGroupByClause
        statement_model.getGroupByClause.getGroupByExpressions.each do |item|
          dig.call(item)
        end
      end

      if statement_model.getOrderByClause
        statement_model.getOrderByClause.getOrderByExpressions.each do |item|
          dig.call(item)
        end
      end

      if statement_model.getHavingClause
        dig.call(statement_model.getHavingClause)
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
