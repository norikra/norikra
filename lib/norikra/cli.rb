require 'norikra/server'
require 'thor'

module Norikra
  class CLI < Thor
    desc "start", "start Norikra server process"
    option :host, :type => :string, :default => '0.0.0.0', :aliases => "-H", :desc => 'host address that server listen [0.0.0.0]'
    option :port, :type => :numeric, :default => 26571, :aliases => "-P", :desc => 'port that server uses [26571]'
    # option :config, :type => :string, :default => nil, :aliases => "-c", :desc => 'configuration file to define table/query [none]'
    # option :daemonize, :type => :boolean, :default => false, :aliases => "-d", :desc => 'daemonize Norikra server [false]'
    # option :pidfile, :type => :string, :default => '/var/run/norikra.pid', :aliases => "-p", :desc => "pidfile path when daemonized [/var/run/norikra.pid]"
    # option :logfile, :type => :string, :default => '/var/log/norikra.log', :aliases => "-l", :desc => "logfile path when daemonized [/var/log/norikra.log]"

    #TODO: configuration file to init
    #TODO: daemonize
    #  TODO: pidcheck
    #  TODO: open logfile & write
    #  TODO: logfile reopen
    def start
      server = Norikra::Server.new(options[:host], options[:port])
      server.run
    end
  end
end
