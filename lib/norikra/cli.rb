require 'norikra/server'
require 'norikra/error'
require 'thor'

require 'rbconfig'

module Norikra
  DEFAULT_PID_PATH = '/var/run/norikra/norikra.pid'

  module CLIUtil
    def self.register_common_start_options(klass)
      klass.module_exec {
        ### Server options
        option :host, :type => :string, :default => nil, :aliases => "-H", :desc => 'host address that server listen [0.0.0.0]'
        option :port, :type => :numeric, :default => nil, :aliases => "-P", :desc => 'port that server uses [26571]'
        option :'ui-port', :type => :numeric, :default => nil, :desc => 'port that Web UI server uses [26578]'

        option :stats, :type => :string, :default => nil, :aliases => "-s", \
                       :desc => 'status file path to load/dump targets and queries [none]'
        option :'stats-secondary', :type => :string, :default => nil, \
                       :desc => 'status file secondary path, to dump stats with date/time, like "stats.%Y%m%d.json" [none]'
        option :'suppress-dump-stat', :type => :boolean, :default => false, \
                       :desc => 'specify not to update stat file with updated targets/queries on runtime [false]'
        option :'dump-stat-interval', :type => :numeric, :default => nil, \
                       :desc => 'interval(seconds) of status file dumps on runtime [none (on shutdown only)]'

        ### Daemonize options
        option :daemonize, :type => :boolean, :default => false, :aliases => "-d", \
                           :desc => 'daemonize Norikra server [false (foreground)]'
        option :pidfile, :type => :string, :default => DEFAULT_PID_PATH, :aliases => "-p", \
                         :desc => "pidfile path when daemonized [#{DEFAULT_PID_PATH}]"
        option :outfile, :type => :string, :default => nil, \
                         :desc => "stdout redirect file when daemonized [${logdir}/norikra.out]"

        ### JVM options
        option :'bare-jvm', :type => :boolean, :default => false, :desc => "use JVM without any recommended options"
        option :'gc-log', :type => :string, :default => nil, :desc => "output gc logs on specified file path"

        ### Performance options
        # performance predefined configuration sets
        option :micro, :type => :boolean, :default => false, \
               :desc => 'development or testing (inbound:0, outbound:0, route:0, timer:0, rpc:2)'
        option :small, :type => :boolean, :default => false, \
               :desc => 'virtual or small scale servers (inbound:1, outbount:1, route:1, timer:1, rpc:2)'
        option :middle, :type => :boolean, :default => false, \
               :desc => 'rackmount servers (inbound:4, outbound:2, route:2, timer:2, rpc:4)'
        option :large, :type => :boolean, :default => false, \
               :desc => 'high performance servers (inbound: 6, outbound: 6, route:4, timer:4, rpc: 8)'
        # Esper
        option :'inbound-threads',  :type => :numeric, :default => nil, :desc => 'number of threads for inbound data'
        option :'outbound-threads', :type => :numeric, :default => nil, :desc => 'number of threads for outbound data'
        option :'route-threads',    :type => :numeric, :default => nil, :desc => 'number of threads for events routing for query execution'
        option :'timer-threads',    :type => :numeric, :default => nil, :desc => 'number of threads for internal timers for query execution'
        ### about capacity options of esper's capacity-bound queue processing, see Esper's thread reference.
        # http://esper.codehaus.org/esper-4.10.0/doc/reference/en-US/html/configuration.html#config-engine-threading-advanced
        # default nil: unbound queueing
        option :'inbound-thread-capacity',  :type => :numeric, :default => nil
        option :'outbound-thread-capacity', :type => :numeric, :default => nil
        option :'route-thread-capacity',    :type => :numeric, :default => nil
        option :'timer-thread-capacity',    :type => :numeric, :default => nil
        # Jetty
        option :'rpc-threads', :type => :numeric, :default => nil, :desc => 'number of threads for rpc handlers'
        option :'web-threads', :type => :numeric, :default => nil, :desc => 'number of threads for WebUI handlers'

        ### Logging options
        option :logdir, :type => :string, :default => nil, :aliases => "-l", \
               :desc => "directory path of logfiles when daemonized [nil (console for foreground)]"
        option :'log-filesize', :type => :string, :default => nil, :desc => 'log rotation size [10MB]'
        option :'log-backups' , :type => :numeric, :default => nil, :desc => 'log rotation backups [10]'
        option :'log-buffer-lines', :type => :numeric, :default => nil, :desc => 'log lines to fetch from API [1000]'
        option :'log4j-properties-path', :type => :string, :default => nil, :desc => 'path to log4j.properties. ignore other log* options when this option is present'

        ### Loglevel options
        option :'more-quiet',   :type => :boolean, :default => false,                   :desc => 'set loglevel as ERROR'
        option :quiet,          :type => :boolean, :default => false, :aliases => "-q", :desc => 'set loglevel as WARN'
        option :verbose,        :type => :boolean, :default => false, :aliases => "-v", :desc => 'set loglevel as DEBUG'
        option :'more-verbose', :type => :boolean, :default => false,                   :desc => 'set loglevel as TRACE'
      }
    end
  end

  class CLI < Thor
    # JVM defaults w/ ConcurrentGC:
    #    java -XX:+UseConcMarkSweepGC -XX:+PrintFlagsFinal -version
    #    (jruby does not modify flags)
    #
    #   CMSIncrementalMode: not recommended in Java8
    #
    #   CMSInitiatingOccupancyFraction: CMS threshold
    #   CMSInitiatingOccupancyFraction = 100 - MinHeapFreeRatio + CMSTriggerRatio * MinHeapFreeRatio / 100
    #     default: MinHeapFreeRatio=40 CMSTriggerRatio=80 -> CMSInitiatingOccupancyFraction=92
    #
    #   NewRatio=7 (New:Old = 1:7)
    #   InitialSurvivorRatio=8     MinSurvivorRatio=3     SurvivorRatio=8 (Eden:Survivor0:survivor1 = 8:1:1)
    #
    #   MaxTenuringThreshold=4
    #   TargetSurvivorRatio=50
    #    (InitialTenuringThreshold=7 is for Parallel GC/UseAdaptiveSizePolicy)
    #
    #   SoftRefLRUPolicyMSPerMB=1000
    #    ( gc_interval > free_heap * ms_per_mb : clear softref )

    JVM_OPTIONS = [
      '-XX:-UseGCOverheadLimit',
      '-XX:+UseConcMarkSweepGC', '-XX:+UseCompressedOops',
      '-XX:CMSInitiatingOccupancyFraction=70', '-XX:+UseCMSInitiatingOccupancyOnly',
      '-XX:NewRatio=1',
      '-XX:SurvivorRatio=2', '-XX:MaxTenuringThreshold=15', '-XX:TargetSurvivorRatio=80',
      '-XX:SoftRefLRUPolicyMSPerMB=200',
    ]

    JVM_GC_OPTIONS = [
      '-verbose:gc', '-XX:+PrintGCDetails', '-XX:+PrintGCDateStamps',
      '-XX:+HeapDumpOnOutOfMemoryError',
    ]

    ### 'start' and 'serverprocess' have almost same option set (for parse/help)
    ### DIFF: jvm options (-X)
    Norikra::CLIUtil.register_common_start_options(self)
    option :help, :type => :boolean, :default => false, :aliases => "-h", :desc => "show this message"
    desc "start [-Xxxx] [other options]", "Start Norikra server process"
    def start(*optargs)
      if options[:help]
        invoke :help, ["start"]
        return
      end

      ARGV.shift # shift head "start"

      argv = ["serverproc"]
      jruby_options = ['-J-server']

      unless options[:'bare-jvm']
        jruby_options += JVM_OPTIONS.map{|opt| '-J' + opt }
      end

      if options[:'gc-log']
        jruby_options += JVM_GC_OPTIONS.map{|opt| '-J' + opt }
        jruby_options.push "-J-Xloggc:#{options[:'gc-log']}"
      end

      ARGV.each do |arg|
        if arg =~ /^-X(.+)$/
          jruby_options.push('-J-X' + $1)
        elsif arg =~ /^-verbose:gc$/
          jruby_options.push('-J-verbose:gc')
        else
          argv.push(arg)
        end
      end

      # norikra/lib/norikra
      binpath = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'norikra'))

      jruby_path = RbConfig.ruby
      args = jruby_options + [binpath] + argv

      if options[:daemonize]
        unless options[:logdir]
          puts "'logdir' must be specified for '--daemonize'."
          exit(1)
        end

        ## need to close/reopen STDIN/STDOUT/STDERR in child process
        outfile = options[:outfile] || File.join(options[:logdir], '/norikra.out')
        File.open(outfile, 'w'){|file| file.write 'write test on parent process'}

        pidfile = File.open(options[:pidfile], 'w')
        pid = spawn(jruby_path, *args, :pgroup => 0)
        pidfile.write(pid.to_s)
        pidfile.close
        waiting_child = true
        while waiting_child && sleep(1)
          out = File.open(outfile){|f| f.read}
          waiting_child = false if out =~ /working on #{pid}/
        end
        Process.detach(pid)
      else
        exec(jruby_path, *args)
      end
    end

    Norikra::CLIUtil.register_common_start_options(self)
    desc "serverproc", "execute server process actually (don't execute this subcommand directly)", :hide => true
    def serverproc
      conf = {}

      if options[:daemonize]
        conf[:daemonize] = {:outfile => options[:outfile]}
      end

      ### stat file
      conf[:stats] = {
        path: options[:stats], secondary_path: options[:'stats-secondary'],
        suppress: options[:'suppress-dump-stat'], interval: options[:'dump-stat-interval'],
      }

      ### threads
      predefined_selecteds = [:micro, :small, :middle, :large].select{|sym| options[sym]}
      if predefined_selecteds.size > 1
        raise Norikra::ConfigurationError, "one of micro/small/middle/large should be specified"
      end
      conf[:thread] = {
        predefined: predefined_selecteds.first,
        micro: options[:micro], small: options[:small], middle: options[:middle], large: options[:large],
        engine: {inbound:{}, outbound:{}, route_exec:{}, timer_exec:{}},
        rpc: {},
        web: {},
      }
      [:inbound, :outbound, :route_exec, :timer_exec].each do |sym|
        opt_sym = case sym
                  when :route_exec then :route
                  when :timer_exec then :timer
                  else sym
                  end
        conf[:thread][:engine][sym][:threads] = options[:"#{opt_sym}-threads"] if options[:"#{opt_sym}-threads"]
        conf[:thread][:engine][sym][:capacity] = options[:"#{opt_sym}-thread-capacity"] if options[:"#{opt_sym}-thread-capacity"]
      end
      conf[:thread][:rpc][:threads] = options[:'rpc-threads'] if options[:'rpc-threads']
      conf[:thread][:web][:threads] = options[:'web-threads'] if options[:'web-threads']

      ### logs
      loglevel = case
                 when options[:'more-verbose'] then 'TRACE'
                 when options[:verbose]        then 'DEBUG'
                 when options[:quiet]          then 'WARN'
                 when options[:'more-quiet']   then 'ERROR'
                 else nil # for default (assumed as 'INFO')
                 end
      conf[:log] = {
        level: loglevel, dir: options[:logdir],
        filesize: options[:'log-filesize'], backups: options[:'log-backups'],
        bufferlines: options[:'log-buffer-lines'],
      }
      conf[:log4j_properties_path] = options[:'log4j-properties-path']

      server_options = {
        host: options[:host],
        port: options[:port],
        ui_port: options[:'ui-port'],
      }

      server = Norikra::Server.new( server_options, conf )
      server.run
      server.shutdown
    end

    option :pidfile, :type => :string, :default => DEFAULT_PID_PATH, :aliases => "-p", \
                     :desc => "pidfile path when daemonized [#{DEFAULT_PID_PATH}]"
    option :timeout, :type => :numeric, :default => 5, :desc => "timeout seconds to wait process exit [5]"
    desc "stop [options]", "stop daemonized Norikra server"
    def stop
      unless test(?r,options[:pidfile])
        puts "Cannot find pidfile at #{options[:pidfile]}"
        exit(1)
      end
      pid = File.open(options[:pidfile]){|f| f.read}.to_i
      timeout = Time.now + options[:timeout]
      waiting = true
      Process.kill(:TERM, pid)
      begin
        while waiting && Time.now < timeout
          sleep(0.5)
          status = Process.waitpid(pid, Process::WNOHANG)
          if status
            waiting = false
          end
        end
      rescue Errno::ECHILD
        waiting = false
      end
      if waiting
        puts "Faild to stop Norikra server #{pid}"
        exit(1)
      else
        File.unlink(options[:pidfile])
      end
    end
  end
end
