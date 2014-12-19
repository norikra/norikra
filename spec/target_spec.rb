require_relative './spec_helper'

require 'norikra/target'
# require 'norikra/error'

describe Norikra::Target do
  describe '.valid?' do
    it 'raises Norikra::ArgumentError for invalid name' do
      expect(Norikra::Target.valid?('foobar')).to be_truthy
      expect(Norikra::Target.valid?('FooBar')).to be_truthy
      expect(Norikra::Target.valid?('foo_bar')).to be_truthy
      expect(Norikra::Target.valid?('foo_bar_baz')).to be_truthy

      expect(Norikra::Target.valid?('')).to be_falsy
      expect(Norikra::Target.valid?('.')).to be_falsy
      expect(Norikra::Target.valid?('_')).to be_falsy
      expect(Norikra::Target.valid?('_a_')).to be_falsy
      expect(Norikra::Target.valid?('foo_')).to be_falsy
      expect(Norikra::Target.valid?('_Foo')).to be_falsy
      expect(Norikra::Target.valid?('foo bar')).to be_falsy
      expect(Norikra::Target.valid?('_Foo')).to be_falsy
    end
  end

  describe '==' do
    it 'returns true whenever 2 targets have same name' do
      t1 = Norikra::Target.new("target1")
      t2 = Norikra::Target.new("target2")
      t3 = Norikra::Target.new("target3")
      tt = Norikra::Target.new("target1")

      expect(t1 == tt).to be_truthy
      expect(t2 == tt).to be_falsy
      expect(t3 == tt).to be_falsy

      expect([t1, t2, t3].include?(tt)).to be_truthy
      expect([t2, t3].include?(tt)).to be_falsy

      expect([t1, t2, t3].include?("target1")).to be_truthy
    end
  end
end
