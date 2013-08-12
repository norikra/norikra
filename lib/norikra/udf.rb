require 'norikra/error'
require 'rubygems'

module Norikra
  module UDF
    #### esper-4.9.0/esper/doc/reference/html/extension.html#custom-singlerow-function
    # <esper-configuration
    #   <plugin-singlerow-function name="getDate"
    #     function-class="mycompany.DateUtil" function-method="parseDate"
    #     value-cache="enabled"
    #     filter-optimizable="disabled"
    #     rethrow-exceptions="disabled" />
    # </esper-configuration>
    class Base
      def self.init
        true
      end

      def definition
        [self.function_name, self.class_name, self.method_name]
      end

      # UDF function name in queries
      def function_name
        raise NotImplementedError
      end

      def class_name
        raise NotImplementedError
      end

      def method_name
        function_name
      end

      # 17.3.3. Value Cache
      # When a single-row function receives parameters that are all constant values or expressions
      # that themselves receive only constant values, Esper can pre-evaluate the result of
      # the single-row function at time of statement creation.
      # By default, Esper does not pre-evaluate the single-row function unless you configure
      # the value cache as enabled.
      def value_cache
        false
      end

      # 17.3.4. Single-Row Functions in Filter Predicate Expressions
      # Your EPL may use plug-in single row functions among the predicate expressions
      # as part of the filters in a stream or pattern.
      # For example, the EPL below uses the function computeHash as part of a predicate expression:
      #
      #    select * from MyEvent(computeHash(field) = 100)
      #
      # When you have many EPL statements or many context partitions that refer to the same function,
      # event type and parameters in a predicate expression, the engine may optimize evaluation:
      # The function gets evaluated only once per event.
      #
      # While the optimization is enabled by default for all plug-in single row functions,
      # you can also disable the optimization for a specific single-row function.
      # By disabling the optimization for a single-row function the engine may use less memory
      # to identify reusable function footprints but may cause the engine to evaluate each function
      # more frequently then necessary.
      def filter_optimizable
        true
      end

      # 17.3.7. Exception Handling
      # By default the engine logs any exceptions thrown by the single row function and returns
      # a null value. To have exceptions be re-thrown instead, which makes exceptions visible
      # to any registered exception handler, please configure as discussed herein.
      def rethrow_exceptions
        false
      end
    end

    def self.listup
      return unless defined? Gem

      plugins = Gem.find_files('norikra/udf/*.rb')
      plugins.each do |plugin|
        begin
          debug "plugin file found!", :file => plugin
          load plugin
        rescue => e
          warn "Failed to load norikra UDF plugin", :plugin => plugin.to_s, :error_class => e.class, :error => e.message
        end
      end

      known_consts = [:Base]
      udfs = []
      self.constants.each do |c|
        next if known_consts.include?(c)

        klass = Norikra::UDF.const_get(c)
        if klass.is_a?(Class) && klass.is_a?(Norikra::UDF::Base)
          udfs.push(klass)
        elsif klass.is_a?(Module) && klass.respond_to?(:plugins)
          udfs.push(klass)
        end
      end
      udfs
    end
  end
end
