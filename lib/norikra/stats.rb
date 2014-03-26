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

    def dump(path)
      tmp_path = path + '.tmp'
      File.open(tmp_path, 'w') do |file|
        file.write(self.to_json)
      end
      File.rename(tmp_path, path)
    end

    def self.load(path)
      File.open(path, 'r') do |file|
        self.new(JSON.parse(file.read, symbolize_names: true))
      end
    end
  end
end
