require 'java'
require 'esper/lib/commons-logging-1.1.1.jar'

require 'monitor'

#### To use this logger
# require 'norikra/logger'
# include Norikra::Log
# # and
## info "message..."
## debug "debugging...", :args => parameters, :status => 'status'

module Norikra
  # 2013-06-21 15:49:30 +0900 [INFO](main) : this is error log, status:'404', message:'content not found'

  # devmode
  # 2013-06-21 15:49:30 +0900 [INFO](main) /path/of/logger.rb:27(method): this is error log, status:'404', message:'content not found'

  # 2013-06-21 15:49:30 +0900 [info](main) MESSAGE
  LOG_LOG4J_FORMAT = '%d{yyyy-MM-dd HH:mm:ss Z} [%p] %m%n'
  LOG_FORMAT = '%s: %s%s'

  LOG_LOG4J_BUILTIN_FORMAT =  '%d{yyyy-MM-dd HH:mm:ss Z} [%p](%t)<%c> %m%n'

  LOGFILE_DEFAULT_MAX_SIZE = '10MB'
  LOGFILE_DEFAULT_MAX_BACKUP_INDEX = 10

  LOG_LEVELS = ['TRACE','DEBUG','INFO','WARN','ERROR','FATAL'].freeze
  LOG_LEVEL_DEFAULT = 'INFO'

  LEVEL_TRACE = LOG_LEVELS.index('TRACE')
  LEVEL_DEBUG = LOG_LEVELS.index('DEBUG')
  LEVEL_INFO  = LOG_LEVELS.index('INFO')
  LEVEL_WARN  = LOG_LEVELS.index('WARN')
  LEVEL_ERROR = LOG_LEVELS.index('ERROR')

  module Log
    @@logger = nil

    @@level = nil
    @@levelnum = nil
    @@devmode = false

    @@mon = Monitor.new

    def self.init(level, logdir, opts, devmode=false)
      level ||= LOG_LEVEL_DEFAULT
      # logdir: nil => ConsoleAppender
      #         else => RollingFileAppender (output: directory path)
      # http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/RollingFileAppender.html

      @@level = level.upcase
      raise ArgumentError, "unknown log level: #{@@level}" unless LOG_LEVELS.include?(@@level)
      @@levelnum = LOG_LEVELS.index(@@level)

      p = java.util.Properties.new
      p.setProperty('log4j.appender.default.layout', 'org.apache.log4j.PatternLayout')
      p.setProperty('log4j.appender.default.layout.ConversionPattern', LOG_LOG4J_FORMAT)

      # for esper epl & mizuno jetty
      esper_log_limit = 'WARN'
      p.setProperty('log4j.logger.com.espertech.esper', "#{esper_log_limit}, builtin")
      mizuno_log_limit = 'WARN'
      p.setProperty('log4j.logger.ruby', "#{mizuno_log_limit}, builtin")
      p.setProperty('log4j.logger.org.eclipse.jetty', "#{mizuno_log_limit}, builtin")

      p.setProperty('log4j.appender.builtin.layout', 'org.apache.log4j.PatternLayout')
      p.setProperty('log4j.appender.builtin.layout.ConversionPattern', LOG_LOG4J_BUILTIN_FORMAT)

      if logdir.nil?
        p.setProperty('log4j.appender.default', 'org.apache.log4j.ConsoleAppender')
        p.setProperty('log4j.appender.builtin', 'org.apache.log4j.ConsoleAppender')
      else
        # DailyRollingFileAppender ?
        # http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/DailyRollingFileAppender.html
        norikra_log = File.join(logdir, 'norikra.log')
        p.setProperty('log4j.appender.default', 'org.apache.log4j.RollingFileAppender')
        p.setProperty('log4j.appender.default.File', norikra_log)
        p.setProperty('log4j.appender.default.MaxFileSize', opts[:filesize] || LOGFILE_DEFAULT_MAX_SIZE)
        p.setProperty('log4j.appender.default.MaxBackupIndex', opts[:backups].to_s || LOGFILE_DEFAULT_MAX_BACKUP_INDEX.to_s)

        builtin_log = File.join(logdir, 'builtin.log')
        p.setProperty('log4j.appender.builtin', 'org.apache.log4j.RollingFileAppender')
        p.setProperty('log4j.appender.builtin.File', builtin_log)
        p.setProperty('log4j.appender.builtin.MaxFileSize', opts[:filesize] || LOGFILE_DEFAULT_MAX_SIZE)
        p.setProperty('log4j.appender.builtin.MaxBackupIndex', opts[:backups].to_s || LOGFILE_DEFAULT_MAX_BACKUP_INDEX.to_s)
      end

      p.setProperty('log4j.rootLogger', "#{@@level},default")
      org.apache.log4j.PropertyConfigurator.configure(p)

      @@logger = Logger.new('norikra.log')

      @@devmode = devmode
    end

    def self.swap(logger) # for tests
      @@mon.synchronize do
        original,@@logger = @@logger, logger
        yield
        @@logger = original
      end
    end

    def trace(message, data=nil)
      return if LEVEL_TRACE < @@levelnum
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.trace(message, data, from)
    end

    def debug(message, data=nil)
      return if LEVEL_DEBUG < @@levelnum
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.debug(message, data, from)
    end

    def info(message, data=nil)
      return if LEVEL_INFO < @@levelnum
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.info(message, data, from)
    end

    def warn(message, data=nil)
      return if LEVEL_WARN < @@levelnum
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.warn(message, data, from)
    end

    def error(message, data=nil)
      return if LEVEL_ERROR < @@levelnum
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.error(message, data, from)
    end

    def fatal(message, data=nil)
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.fatal(message, data, from)
    end
  end

  class Logger
    def initialize(name)
      @log4j = org.apache.commons.logging.LogFactory.getLog(name)
    end

    def trace(message, data=nil, from=nil)
      @log4j.trace(format(from, message, data))
    end

    def debug(message, data=nil, from=nil)
      @log4j.debug(format(from, message, data))
    end

    def info(message, data=nil, from=nil)
      @log4j.info(format(from, message, data))
    end

    def warn(message, data=nil, from=nil)
      @log4j.warn(format(from, message, data))
    end

    def error(message, data=nil, from=nil)
      @log4j.error(format(from, message, data))
    end

    def fatal(message, data=nil, from=nil)
      @log4j.fatal(format(from, message, data))
    end

    def format_location(locations)
      return '' if locations.nil?
      c = locations.first
      "#{c.path}:#{c.lineno}(#{c.label})"
    end

    def format_data(data=nil)
      return '' if data.nil?

      #, status:404, message:'content not found'
      if data.is_a?(Proc)
        ', ' + format_data(data.call)
      elsif data.is_a?(Hash)
        ', ' + data.map{|k,v| "#{k}:#{v.inspect}"}.join(', ')
      else
        ', ' + data.inspect
      end
    end

    def format(from, message, data)
      # LOG_FORMAT = '%s: %s%s'
      LOG_FORMAT % [format_location(from), message, format_data(data)]
    end
  end

  class DummyLogger < Logger # for tests
    # LOG_LOG4J_FORMAT = '%d{yyyy-MM-dd HH:mm:ss Z} [%p] %m%n'
    # LOG_FORMAT = '%s: %s%s'
    FORMAT_SIMULATED = "%s [%s] %s\n"
    FORMAT_SIMULATED_TIME = '%Y-%m-%d %H:%M:%S %z'
    attr_accessor :logs, :output
    def initialize
      @logs = { :TRACE => [], :DEBUG => [], :INFO => [], :WARN => [], :ERROR => [], :FATAL => [] }
      @output = []
    end
    def log(level, message, data, from)
      @logs[level].push({:message => message, :data => data, :from => from})
      formatted = sprintf(FORMAT_SIMULATED, Time.now.strftime(FORMAT_SIMULATED_TIME), level.to_s, format(from, message, data))
      @output.push(formatted)
    end
    def trace(m,d,f); self.log(:TRACE,m,d,f); end
    def debug(m,d,f); self.log(:DEBUG,m,d,f); end
    def info(m,d,f) ; self.log(:INFO, m,d,f); end
    def warn(m,d,f) ; self.log(:WARN, m,d,f); end
    def error(m,d,f); self.log(:ERROR,m,d,f); end
    def fatal(m,d,f); self.log(:FATAL,m,d,f); end
  end
end

require_relative './logger_mizuno_patch'
