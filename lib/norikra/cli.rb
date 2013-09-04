require 'norikra/server'
require 'norikra/error'
require 'thor'

module Norikra
  DEFAULT_PID_PATH = '/var/run/norikra/norikra.pid'

  module CLIUtil
    def self.register_common_start_options(klass)
      klass.module_exec {
        ### Server options
        option :host, :type => :string, :default => nil, :aliases => "-H", :desc => 'host address that server listen [0.0.0.0]'
        option :port, :type => :numeric, :default => nil, :aliases => "-P", :desc => 'port that server uses [26571]'

        option :stats, :type => :string, :default => nil, :aliases => "-s", \
                       :desc => 'status file path to load/dump targets, queries and server configurations [none]'
        option :'suppress-dump-stat', :type => :boolean, :default => false, \
                       :desc => 'specify not to update stat file with updated targets/queries/configurations on runtime [false]'

        ### Daemonize options
        option :daemonize, :type => :boolean, :default => false, :aliases => "-d", \
                           :desc => 'daemonize Norikra server [false (foreground)]'
        option :pidfile, :type => :string, :default => DEFAULT_PID_PATH, :aliases => "-p", \
                         :desc => "pidfile path when daemonized [#{DEFAULT_PID_PATH}]"
        option :outfile, :type => :string, :default => nil, \
                         :desc => "stdout redirect file when daemonized [${logdir}/norikra.out]"

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
        option :'inbound-thread-capacity',  :type => :numeric, :default => nil
        option :'outbound-thread-capacity', :type => :numeric, :default => nil
        option :'route-thread-capacity',    :type => :numeric, :default => nil
        option :'timer-thread-capacity',    :type => :numeric, :default => nil
        # Jetty
        option :'rpc-threads', :type => :numeric, :default => nil, :desc => 'number of threads for rpc handlers'

        ### Logging options
        option :logdir, :type => :string, :default => nil, :aliases => "-l", \
               :desc => "directory path of logfiles when daemonized [nil (console for foreground)]"
        option :'log-filesize', :type => :string, :default => nil, :desc => 'log rotation size [10MB]'
        option :'log-backups' , :type => :numeric, :default => nil, :desc => 'log rotation backups [10]'

        ### Loglevel options
        option :'more-quiet',   :type => :boolean, :default => false,                   :desc => 'set loglevel as ERROR'
        option :quiet,          :type => :boolean, :default => false, :aliases => "-q", :desc => 'set loglevel as WARN'
        option :verbose,        :type => :boolean, :default => false, :aliases => "-v", :desc => 'set loglevel as DEBUG'
        option :'more-verbose', :type => :boolean, :default => false,                   :desc => 'set loglevel as TRACE'
      }
    end
  end

  class CLI < Thor
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
      jruby_options = ['-J-server', '-J-XX:-UseGCOverheadLimit']

      ARGV.each do |arg|
        if arg =~ /^-X(.+)$/
          jruby_options.push('-J-X' + $1)
        else
          argv.push(arg)
        end
      end

      # norikra/lib/norikra
      binpath = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'norikra'))
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
        pid = spawn('jruby', *args, :pgroup => 0)
        pidfile.write(pid.to_s)
        pidfile.close
        waiting_child = true
        while waiting_child && sleep(1)
          out = File.open(outfile){|f| f.read}
          waiting_child = false if out =~ /working on #{pid}/
        end
        Process.detach(pid)
      else
        exec('jruby', *args)
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
        path: options[:stats], suppress: options[:'suppress-dump-stat'],
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
      }
      [:inbound, :outbound, :route_exec, :timer_exec].each do |sym|
        conf[:thread][:engine][sym][:threads] = options[:"#{sym}-threads"] if options[:"#{sym}-threads"]
        conf[:thread][:engine][sym][:capacity] = options[:"#{sym}-thread-capacity"] if options[:"#{sym}-thread-capacity"]
      end
      conf[:thread][:rpc][:threads] = options[:'rpc-threads'] if options[:'rpc-threads']

      ### logs
      loglevel = case
                 when options[:'more-verbose'] then 'TRACE'
                 when options[:verbose]        then 'DEBUG'
                 when options[:quiet]          then 'WARN'
                 when options[:'more-quiet']   then 'ERROR'
                 else nil # for default (assumed as 'INFO')
                 end
      conf[:log] = {
        level: loglevel, dir: options[:logdir], filesize: options[:'log-filesize'], backups: options[:'log-backups'],
      }

      server = Norikra::Server.new( options[:host], options[:port], conf )
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
