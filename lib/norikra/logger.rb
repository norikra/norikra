require 'java'
require 'esper/lib/commons-logging-1.1.3.jar'

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

    @@devmode = false

    @@test_flag = false

    @@mon = Monitor.new

    def self.init(level, logdir, opts, devmode=false)
      level ||= LOG_LEVEL_DEFAULT
      # logdir: nil => ConsoleAppender
      #         else => RollingFileAppender (output: directory path)
      # http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/RollingFileAppender.html

      if level.upcase == 'TEST' # with opts[:logger] as DummyLogger instance
        level = opts[:level] || LOG_LEVEL_DEFAULT
        @@test_flag = true
      end

      level = level.upcase
      raise ::ArgumentError, "unknown log level: #{level}" unless LOG_LEVELS.include?(level)

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

      unless @@test_flag
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
        p.setProperty('log4j.rootLogger', "#{level},default")
        org.apache.log4j.PropertyConfigurator.configure(p)

        @@logger = Logger.new('norikra.log', opts)

      else # for test(rspec)
        p.setProperty('log4j.appender.default', 'org.apache.log4j.varia.NullAppender')
        p.setProperty('log4j.appender.builtin', 'org.apache.log4j.varia.NullAppender')
        p.setProperty('log4j.rootLogger', "#{level},default")
        org.apache.log4j.PropertyConfigurator.configure(p)
        @@logger = opts[:logger]
      end

      @@devmode = devmode
    end

    def self.init_with_log4j_properties_path(log4j_properties_path)
      org.apache.log4j.PropertyConfigurator.configure(log4j_properties_path)
      @@logger = Logger.new('norikra.log')
      @@devmode = false
    end

    def self.swap(logger) # for tests
      @@mon.synchronize do
        original,@@logger = @@logger, logger
        yield
        @@logger = original
      end
    end

    def self.logger; @@logger ; end

    def trace(message, data=nil, &block)
      return unless @@logger.enabled?(LEVEL_TRACE)
      data ||= block
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.trace(message, data, from)
    end

    def debug(message, data=nil, &block)
      return unless @@logger.enabled?(LEVEL_DEBUG)
      data ||= block
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.debug(message, data, from)
    end

    def info(message, data=nil, &block)
      return unless @@logger.enabled?(LEVEL_INFO)
      data ||= block
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.info(message, data, from)
    end

    def warn(message, data=nil, &block)
      return unless @@logger.enabled?(LEVEL_WARN)
      data ||= block
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.warn(message, data, from)
    end

    def error(message, data=nil, &block)
      return unless @@logger.enabled?(LEVEL_ERROR)
      data ||= block
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.error(message, data, from)
    end

    def fatal(message, data=nil, &block)
      # always enabled
      data ||= block
      from = @@devmode ? caller_locations(1,1) : nil
      @@logger.fatal(message, data, from)
    end
  end

  class Logger
    attr_reader :buffer

    DEFAULT_MEMORY_BUFFER_LINES = 1000
    TIME_FORMAT = '%Y-%m-%d %H:%M:%S %z'

    def initialize(name, opts={})
      @log4j = org.apache.commons.logging.LogFactory.getLog(name)
      @buffer = Array.new
      @buffer_lines = opts[:bufferlines] || DEFAULT_MEMORY_BUFFER_LINES
    end

    def push(level, line)
      if @buffer.size == @buffer_lines
        @buffer.shift
      end
      @buffer << [Time.now.strftime(TIME_FORMAT), level, line]
    end

    def enabled?(level)
      case level
      when LEVEL_TRACE then @log4j.isTraceEnabled
      when LEVEL_DEBUG then @log4j.isDebugEnabled
      when LEVEL_INFO  then @log4j.isInfoEnabled
      when LEVEL_WARN  then @log4j.isWarnEnabled
      when LEVEL_ERROR then @log4j.isErrorEnabled
      else true
      end
    end

    def trace(message, data=nil, from=nil)
      return unless @log4j.isTraceEnabled
      line = format(from, message, data)
      push('trace', line)
      @log4j.trace(line)
    end

    def debug(message, data=nil, from=nil)
      return unless @log4j.isDebugEnabled
      line = format(from, message, data)
      push('debug', line)
      @log4j.debug(line)
    end

    def info(message, data=nil, from=nil)
      return unless @log4j.isInfoEnabled
      line = format(from, message, data)
      push('info', line)
      @log4j.info(line)
    end

    def warn(message, data=nil, from=nil)
      return unless @log4j.isWarnEnabled
      line = format(from, message, data)
      push('warn', line)
      @log4j.warn(line)
    end

    def error(message, data=nil, from=nil)
      return unless @log4j.isErrorEnabled
      line = format(from, message, data)
      push('error', line)
      @log4j.error(line)
    end

    def fatal(message, data=nil, from=nil)
      return unless @log4j.isFatalEnabled
      line = format(from, message, data)
      push('fatal', line)
      @log4j.fatal(line)
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
        format_data(data.call)
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
    attr_accessor :logs, :output
    def initialize
      @logs = { TRACE: [], DEBUG: [], INFO: [], WARN: [], ERROR: [], FATAL: [] }
      @output = []
    end
    def log(level, message, data, from)
      @logs[level].push({message: message, data: data, from: from})
      formatted = sprintf(FORMAT_SIMULATED, Time.now.strftime(TIME_FORMAT), level.to_s, format(from, message, data))
      @output.push(formatted)
    end
    def enabled?(level); true; end
    def trace(m,d,f); self.log(:TRACE,m,d,f); end
    def debug(m,d,f); self.log(:DEBUG,m,d,f); end
    def info(m,d,f) ; self.log(:INFO, m,d,f); end
    def warn(m,d,f) ; self.log(:WARN, m,d,f); end
    def error(m,d,f); self.log(:ERROR,m,d,f); end
    def fatal(m,d,f); self.log(:FATAL,m,d,f); end
  end
end

require_relative './logger_mizuno_patch'
