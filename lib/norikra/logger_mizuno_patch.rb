require 'java'
require 'esper/lib/log4j-1.2.16.jar'
require 'mizuno/logger'

module Mizuno
  class Logger
    def Logger.configure(options = {})
      return if @options
      @options = options

      ### built-in jetty log level is fixed as 'WARN' for Norikra
      ### Base logging configuration.
      # mizuno_log_limit = "WARN"
      # config = <<-END
      #   log4j.logger.ruby = #{mizuno_log_limit}
      #   log4j.logger.org.eclipse.jetty.util.log = #{mizuno_log_limit}, ruby
      # END

      ### appender configuration will be done out of mizuno

      # Create the default logger that gets used everywhere.
      @logger = new
    end
  end
end


