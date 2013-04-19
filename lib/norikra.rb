unless RUBY_PLATFORM =~ /java/
  raise LoadError, 'Only supports JRuby'
end

require 'norikra/version'

require 'norikra/query'

require 'norikra/type_manager'
require 'norikra/output_pool'
require 'norikra/engine'

# require messagepack rpc server thread
# require http manager server thread
