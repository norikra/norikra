require 'json'

module Norikra
  class Stats
    attr_accessor :targets, :queries

    def self.generate(engine)
      Norikra::Stats.new(
        targets: engine.targets.map{|t|
          {
            :name => t.name,
            :fields => engine.typedef_manager.dump_target(t.name),
            :auto_field => t.auto_field
          }
        },
        queries: engine.queries.map(&:dump)
      )
    end

    def initialize(opts={})
      @targets = opts[:targets] || []
      @queries = opts[:queries] || []
    end

    def to_hash
      {targets: @targets, queries: @queries}
    end

    def to_json
      JSON.pretty_generate(self.to_hash)
    end

    def dump(path, secondary_path)
      require 'tempfile'
      tmp = Tempfile.open(path)
      begin
        tmp.write(self.to_json)
        tmp.flush
        if secondary_path
          require 'fileutils'
          secondary_actual_path = Time.now.strftime(secondary_path)
          FileUtils.copy(tmp.path, secondary_actual_path)
        end
        File.rename(tmp.path, path)
      ensure
        tmp.close!
      end
    end

    def self.load(path)
      File.open(path, 'r') do |file|
        self.new(JSON.parse(file.read, symbolize_names: true))
      end
    end
  end
end
