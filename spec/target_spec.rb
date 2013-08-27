require_relative './spec_helper'

require 'norikra/target'
# require 'norikra/error'

describe Norikra::Target do
  describe '.valid?' do
    it 'raises Norikra::ArgumentError for invalid name' do
      expect(Norikra::Target.valid?('foobar')).to be_true
      expect(Norikra::Target.valid?('FooBar')).to be_true
      expect(Norikra::Target.valid?('foo_bar')).to be_true
      expect(Norikra::Target.valid?('foo_bar_baz')).to be_true

      expect(Norikra::Target.valid?('')).to be_false
      expect(Norikra::Target.valid?('.')).to be_false
      expect(Norikra::Target.valid?('_')).to be_false
      expect(Norikra::Target.valid?('_a_')).to be_false
      expect(Norikra::Target.valid?('foo_')).to be_false
      expect(Norikra::Target.valid?('_Foo')).to be_false
      expect(Norikra::Target.valid?('foo bar')).to be_false
      expect(Norikra::Target.valid?('_Foo')).to be_false
    end
  end
end
