require_relative './spec_helper'

require 'norikra/stats'
require 'norikra/server'

require 'tmpdir'

describe Norikra::Stats do
  describe '#to_hash' do
    it 'returns internal stats as hash with symbolized keys' do
      args = {
        host: nil,
        port: nil,
        ui_port: nil,
        threads: Norikra::Server::SMALL_PREDEFINED,
        log: {level: nil, dir: nil, filesize: nil, backups: nil},
        targets: [],
        queries: [],
      }
      s = Norikra::Stats.new(args)
      expect(s.to_hash).to eql(args)
    end
  end

  describe '.load' do
    it 'can restore stats data from #dump -ed json' do
      Dir.mktmpdir do |dir|
        File.open("#{dir}/stats.json", 'w') do |file|
          args = {
            host: nil,
            port: nil,
            ui_port: nil,
            threads: Norikra::Server::LARGE_PREDEFINED,
            log: {level: 'WARN', dir: '/var/log/norikra', filesize: '50MB', backups: 300},
            targets: [
              { name: 'test1', fields: { id: { name: 'id', type: 'int', optional: false}, data: { name: 'data', type: 'string', optional: true } } },
            ],
            queries: [
              { name: 'testq2', expression: 'select count(*) from test1.win:time(5 sec)' },
              { name: 'testq1', expression: 'select count(*) from test1.win:time(10 sec)' },
            ],
          }
          s1 = Norikra::Stats.new(args)
          expect(s1.to_hash).to eql(args)

          s1.dump(file.path)

          s2 = Norikra::Stats.load(file.path)
          expect(s2.to_hash).to eql(s1.to_hash)
          expect(s2.to_hash).to eql(args)
        end
      end
    end
  end
end
