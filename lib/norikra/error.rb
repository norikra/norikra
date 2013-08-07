module Norikra
  class ClientError < StandardError; end
  class ArgumentError < ClientError; end
  class QueryError < ClientError; end
end
