require 'json'

module Norikra
  class Stats
    attr_accessor :host, :port, :threads, :log
    attr_accessor :targets, :queries

    def initialize(opts={})
      @host = opts[:host]
      @port = opts[:port]
      @threads = opts[:threads]
      @log = opts[:log]
      @targets = opts[:targets] || []
      @queries = opts[:queries] || []
    end

    def to_hash
      {host: @host, port: @port, threads: @threads, log: @log, targets: @targets, queries: @queries}
    end

    def dump(path)
      File.open(path, 'w') do |file|
        file.write(JSON.pretty_generate(self.to_hash))
      end
    end

    def self.load(path)
      File.open(path, 'r') do |file|
        self.new(JSON.parse(file.read, symbolize_names: true))
      end
    end
  end
end
