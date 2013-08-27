# this is note for future update

# module Norikra
#   module UDF
#     class FailedUDFImplementationPureRuby
#       # require 'jruby/core_ext'
#       class WootheeIsCrawler < Norikra::UDF::Base # Norikra::UDF::WootheeIsCrawler < Norikra::UDF::Base
#         def self.init
#           require 'woothee'
#         end

#         def self.function_name
#           "isCrawler"
#         end

#         def self.isCrawler(agent)
#           Woothee.is_crawler(agent)
#         end
#         class << self
#           add_method_signature( "isCrawler", [java.lang.Boolean, java.lang.String] )
#         end
#       end

#       # for engine.rb
#       def load_udf_actually(udf_klass)
#         require 'jruby/core_ext'
#         udf_klass.init

#         jclass = udf_klass.become_java!(".")
#         className = jclass.get_name.to_java(:string)

#         #### try for NullPointerException, but doesn't work well
#         # field = jclass.getDeclaredField("ruby");
#         # field.setAccessible(java.lang.Boolean::TRUE)
#         # field.set(nil, org.jruby.Ruby.getGlobalRuntime)

#         functionName = udf_klass.function_name.to_java(:string)
#         methodName = udf_klass.method_name.to_java(:string)

#         valueCache = udf_klass.value_cache ? VALUE_CACHE_ENUM::ENABLED : VALUE_CACHE_ENUM::DISABLED
#         filterOptimizable = udf_klass.filter_optimizable ? FILTER_OPTIMIZABLE_ENUM::ENABLED : FILTER_OPTIMIZABLE_ENUM::DISABLED
#         rethrowExceptions = udf_klass.rethrow_exceptions

#         debug "adding SingleRowFunction", :class => udf_klass.to_s, :javaClass => jclass.get_name
#         @config.addPlugInSingleRowFunction(functionName, className, methodName, valueCache, filterOptimizable, rethrowExceptions)
#       end
#     end
#   end
# end
