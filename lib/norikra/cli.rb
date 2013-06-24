require 'norikra/server'
require 'thor'

module Norikra
  class CLI < Thor
    desc "start", "start Norikra server process"
    option :host, :type => :string, :default => '0.0.0.0', :aliases => "-H", :desc => 'host address that server listen [0.0.0.0]'
    option :port, :type => :numeric, :default => 26571, :aliases => "-P", :desc => 'port that server uses [26571]'
    # option :config, :type => :string, :default => nil, :aliases => "-c", :desc => 'configuration file to define target/query [none]'

    option :daemonize, :type => :boolean, :default => false, :aliases => "-d", \
                       :desc => 'daemonize Norikra server [false (foreground)]'
    option :pidfile, :type => :string, :default => '/var/run/norikra.pid', :aliases => "-p", \
                     :desc => "pidfile path when daemonized [/var/run/norikra.pid]"

    option :logdir, :type => :string, :default => nil, :aliases => "-l", \
                    :desc => "directory path of logfiles when daemonized [nil (console)]"
    option :'log-filesize', :type => :string, :default => '10MB'
    option :'log-backups' , :type => :numeric, :default => 10

    option :'more-quiet',   :type => :boolean, :default => false,                   :desc => 'set loglevel as ERROR'
    option :quiet,          :type => :boolean, :default => false, :aliases => "-q", :desc => 'set loglevel as WARN'
    option :verbose,        :type => :boolean, :default => false, :aliases => "-v", :desc => 'set loglevel as DEBUG'
    option :'more-verbose', :type => :boolean, :default => false,                   :desc => 'set loglevel as TRACE'

    #TODO: configuration file to init
    def start
      conf = {}

      #TODO: daemonize
      raise NotImplementedError if options[:daemonize]
      #TODO: pidcheck if daemonize

      conf[:loglevel] = case
                        when options[:'more-verbose'] then 'TRACE'
                        when options[:verbose]        then 'DEBUG'
                        when options[:quiet]          then 'WARN'
                        when options[:'more-quiet']   then 'ERROR'
                        else nil # for default (assumed as 'INFO')
                        end
      conf[:logdir] = options[:logdir]
      conf[:logfilesize] = options[:'log-filesize']
      conf[:logbackups] = options[:'log-backups']
      server = Norikra::Server.new( options[:host], options[:port], conf )
      server.run
      server.shutdown
    end
  end
end
