module Norikra
  module UDFSpecHelper
    @@plugins = {}

    def function(name)
      @@plugins[name.to_s]
    end

    def fcall(name, *args)
      @@plugins[name.to_s]._call(*args)
    end

    # params: for AggregationSingle only
    #         required keys: :valueType, :windowed, :distinct, :parameters
    #           :parameters => [[parameterType, constant?, contantValue], ... ]
    def udf_function(mojule, params={})
      esper_jars_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'esper'))
      esper_jar = Dir.entries(esper_jars_dir).select{|f| f =~ /^esper-\d+\.\d+\.\d+\.jar$/}.first
      require esper_jar

      unless mojule.is_a?(Class)
        mojule.init if mojule.respond_to?(:init)
        ps = []
        mojule.plugins.each{|p| ps.push(udf_function(p))} if mojule.respond_to?(:plugins)
        return ps
      end

      klass = mojule
      klass.init if klass.respond_to?(:init)

      if klass.superclass == Norikra::UDF::SingleRow
        name, classname, methodname = klass.new.definition
        @@plugins[name] = UDFInstance.new(classname, methodname)

      elsif klass.superclass == Norikra::UDF::AggregationSingle
        name, factoryclassname = klass.new.definition
        factory = UDFAggregationFactoryInstance.new(factoryclassname)
        factory.check(name, params[:valueType], params[:parameters], params.fetch(:distinct, false), params.fetch(:windowed, true))
        @@plugins[name] = factory.create
      end
    end

    module UDFHelper
      def classObject(classname)
        parts = classname.split('.')
        clazzname = parts.pop
        eval("Java::" + parts.map(&:capitalize).join + "::" + clazzname)
      end
    end

    class UDFInstance
      include UDFHelper

      def initialize(classname, methodname)
        @methodname = methodname
        @clazz = classObject(classname)
      end

      def _call(*args)
        @clazz.send(@methodname.to_sym, *args)
      end
    end

    class UDFAggregationInstance
      def initialize(instance)
        @func = instance
      end

      def _call(type, *args)
        self.send(type, *args)
      end

      def getValueType; @func.getValueType; end # public Class getValueType()
      def enter(*args); @func.enter(*args); end # public void enter(Object value)
      def leave(*args); @func.leave(*args); end # public void leave(Object value)

      def getValue # public Object getValue()
        v = @func.getValue
        if v.respond_to?(:to_hash)
          v.to_hash
        elsif v.respond_to?(:to_a)
          v.to_a
        else
          v
        end
      end

      def clear; @func.clear; end # public void clear()
    end

    class UDFAggregationFactoryInstance
      include UDFHelper

      def initialize(classname)
        @factory = classObject(classname).new
      end

      # parameters => [[parameterType, constant?, contantValue], ... ]
      def check(func_name, value_type, parameters, distinct, windowed)
        @factory.setFunctionName(func_name)
        unless @factory.getValueType == value_type.java_class
          raise "Aggregation UDF value type mismatch, expected '#{value_type}', actually '#{@factory.getValueType}'"
        end

        parameterTypes = parameters.map{|t,bc,c| t.java_class }
        constantValue  = parameters.map{|t,bc,c| bc.nil? ? false : bc }
        constantValues = parameters.map{|t,bc,c| c }

        # public AggregationValidationContext(java.lang.Class[] parameterTypes,
        #                               boolean[] constantValue,
        #                               java.lang.Object[] constantValues,
        #                               boolean distinct,
        #                               boolean windowed,
        #                               ExprNode[] expressions)
        context_class = com.espertech.esper.epl.agg.service.AggregationValidationContext
        context = context_class.new(parameterTypes, constantValue, constantValues, distinct, windowed, [])
        @factory.validate(context)
        true
      end

      def create
        UDFAggregationInstance.new(@factory.newAggregator)
      end
    end
  end
end
