module Norikra
  class ConfigurationError < StandardError; end
  class ClientError < StandardError; end
  class ArgumentError < ClientError; end
  class QueryError < ClientError; end
end
