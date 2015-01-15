# -*- coding: utf-8 -*-
require_relative './spec_helper'

require 'json'
require 'norikra/listener'

class DummyEngine
  attr_reader :events

  def initialize
    @events = {}
  end

  def send(target, events)
    @events[target] ||= []
    @events[target].push(*events)
  end
end

class DummyOutputPool
  attr_reader :pool

  def initialize
    @pool = {}
  end

  def push(query_name, query_group, events)
    @pool[query_group] ||= {}
    @pool[query_group][query_name] ||= []
    @pool[query_group][query_name].push(*events)
  end
end

describe Norikra::Listener::Base do
  it 'should be initialized' do
    statistics = {output: 0}
    expect { Norikra::Listener::Base.new('name', 'group', statistics) }.not_to raise_error
  end

  describe '#type_convert' do
    statistics = {output: 0}
    listener = Norikra::Listener::Base.new('name', 'group', statistics)

    it 'returns value itself for number, boolean and nil' do
      val = 10001
      expect(listener.type_convert(val)).to eq(val)

      val = 100.001
      expect(listener.type_convert(val)).to eq(val)

      val = false
      expect(listener.type_convert(val)).to eq(val)

      val = true
      expect(listener.type_convert(val)).to eq(val)

      val = nil
      expect(listener.type_convert(val)).to eq(val)
    end

    it 'returns String with UTF-8 encoding' do
      val = "a".force_encoding('ASCII-8BIT')
      rval = listener.type_convert(val)
      expect(rval.encoding.to_s).to eql("UTF-8")
      expect(rval).to eql("a")

      val = "乗鞍".force_encoding('ASCII-8BIT')
      rval = listener.type_convert(val)
      expect(rval.encoding.to_s).to eql("UTF-8")
      expect(rval).to eql("乗鞍")
    end

    it 'returns Array for to_a responding objects, with type_convert-ed members' do
      s1 = "乗鞍".force_encoding("ASCII-8BIT")
      val = [100, 100.01, false, true, nil, s1]
      rval = listener.type_convert(val)
      expect(rval).to be_a(Array)
      expect(rval[0]).to eql(100)
      expect(rval[1]).to eql(100.01)
      expect(rval[2]).to eq(false)
      expect(rval[3]).to eq(true)
      expect(rval[4]).to be_nil
      expect(rval[5].encoding.to_s).to eql("UTF-8")
      expect(rval[5]).to eql("乗鞍")
    end

    it 'returns Hash for to_hash responding objects, with unescaped keys and type_convert-ed values' do
      s1 = "乗鞍".force_encoding("ASCII-8BIT")
      val = {
        "100" => 100,
        "100_01" => 100.01,
        "bool$false" => false,
        "bool$true" => true,
        "object$$0" => nil,
        "string" => s1,
        "list" => [0, 1, 2],
        "percentiles" => {
          "10" => 0.1,
          "50" => 0.5,
          "99" => 0.99
        }
      }
      rval = listener.type_convert(val)
      expect(rval).to be_a(Hash)

      expect(rval["100"]).to eql(100)
      expect(rval["100_01"]).to eql(100.01)
      expect(rval["bool.false"]).to eq(false)
      expect(rval["bool.true"]).to eq(true)
      expect(rval["object.$0"]).to be_nil
      expect(rval["string"].encoding.to_s).to eql("UTF-8")
      expect(rval["string"]).to eql("乗鞍")
      expect(rval["list"]).to eql([0,1,2])
      expect(rval["percentiles"]).to eql({"10" => 0.1, "50" => 0.5, "99" => 0.99})
    end
  end
end

describe Norikra::Listener::MemoryPool do
  describe '.check' do
    it 'always returns true' do
      expect(Norikra::Listener::MemoryPool.check(nil)).to be_truthy
      expect(Norikra::Listener::MemoryPool.check('')).to be_truthy
      expect(Norikra::Listener::MemoryPool.check('FOO')).to be_truthy
      expect(Norikra::Listener::MemoryPool.check('FOO()')).to be_truthy
    end
  end

  describe '#update' do
    statistics = {output: 0}
    listener = Norikra::Listener::MemoryPool.new('name', 'group', statistics)
    listener.output_pool = dummy_pool = DummyOutputPool.new

    it 'pushs events into pool, with current time' do
      listener.update([{"n1" => 100, "s" => "string one"}, {"n1" => 101, "s" => "string two"}], [])
      expect(statistics[:output]).to eql(2)
      expect(dummy_pool.pool['group']['name'].size).to eql(2)
      expect(dummy_pool.pool['group']['name'][0][0]).to be_a(Fixnum)
      expect(dummy_pool.pool['group']['name'][0][1]).to eql({"n1" => 100, "s" => "string one"})
      expect(dummy_pool.pool['group']['name'][1][1]).to eql({"n1" => 101, "s" => "string two"})

      listener.update([{"n1" => 102, "s" => "string three"}], [])
      expect(statistics[:output]).to eql(3)
      expect(dummy_pool.pool['group']['name'].size).to eql(3)
    end
  end
end

describe Norikra::Listener::Loopback do
  describe '.check' do
    it 'returns nil for nil group' do
      expect(Norikra::Listener::Loopback.check(nil)).to be_nil
    end

    it 'returns nil for string group name without prefix' do
      expect(Norikra::Listener::Loopback.check('a')).to be_nil
      expect(Norikra::Listener::Loopback.check('group1')).to be_nil
      expect(Norikra::Listener::Loopback.check('LOOPBACK')).to be_nil
    end

    it 'returns specified string as loopback target by parentheses' do
      expect(Norikra::Listener::Loopback.check('LOOPBACK()')).to be_nil
      expect(Norikra::Listener::Loopback.check('LOOPBACK(a)')).to eql('a')
      expect(Norikra::Listener::Loopback.check('LOOPBACK(loopback_target)')).to eql('loopback_target')
      expect(Norikra::Listener::Loopback.check('LOOPBACK(target name)')).to eql('target name') # should be invalid on 'open'
    end
  end

  it 'should be initialized' do
    statistics = {output: 0}
    expect { Norikra::Listener::Loopback.new('name', 'LOOPBACK(target1)', statistics) }.not_to raise_error
  end

  describe '#update' do
    statistics = {output: 0}
    listener = Norikra::Listener::Loopback.new('name', 'LOOPBACK(target1)', statistics)
    listener.engine = dummy_engine = DummyEngine.new

    it 'sends events into engine with target name' do
      listener.update([{"n1" => 100, "s" => "string one"}, {"n1" => 101, "s" => "string two"}], [])
      expect(statistics[:output]).to eql(2)
      expect(dummy_engine.events['target1'].size).to eql(2)
      expect(dummy_engine.events['target1'][0]).to eql({"n1" => 100, "s" => "string one"})
      expect(dummy_engine.events['target1'][1]).to eql({"n1" => 101, "s" => "string two"})

      listener.update([{"n1" => 102, "s" => "string three"}], [])
      expect(statistics[:output]).to eql(3)
      expect(dummy_engine.events['target1'].size).to eql(3)
    end
  end
end

describe Norikra::Listener::Stdout do
  describe '.check' do
    it 'returns true if group name is "STDOUT()"' do
      expect(Norikra::Listener::Stdout.check(nil)).to be_falsy
      expect(Norikra::Listener::Stdout.check("")).to be_falsy
      expect(Norikra::Listener::Stdout.check("foo")).to be_falsy
      expect(Norikra::Listener::Stdout.check("STDOUT")).to be_falsy
      expect(Norikra::Listener::Stdout.check("STDOUT()")).to be_truthy
    end
  end

  it 'should be initialized' do
    statistics = {output: 0}
    expect { Norikra::Listener::Stdout.new('name', 'STDOUT()', statistics) }.not_to raise_error
  end

  describe '#update' do
    statistics = {output: 0}
    listener = Norikra::Listener::Stdout.new('name', 'STDOUT()', statistics)
    dummyio = StringIO.new
    listener.instance_eval{ @stdout = dummyio }

    it 'sends events into engine with target name' do
      dummyio.truncate(0)

      events1 = [{"n1" => 100, "s" => "string one"}, {"n1" => 101, "s" => "string two"}]
      listener.update(events1, [])
      expect(statistics[:output]).to eql(2)

      events2 = [{"n1" => 102, "s" => "string three"}]
      listener.update(events2, [])
      expect(statistics[:output]).to eql(3)

      results = []
      dummyio.string.split("\n").each do |line|
        query_name, json = line.split("\t")
        expect(query_name).to eql("name")
        results << JSON.parse(json) if json && json != ''
      end
      expect(results).to eql(events1 + events2)
    end
  end
end
