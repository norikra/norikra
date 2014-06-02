require_relative './spec_helper'

require 'norikra/engine'

describe Norikra::Engine do
  it 'can be initialized' do
    expect { Norikra::Engine.new(nil, nil) }.not_to raise_error
  end

  describe '#camelize' do
    it 'make CamelizedString from :snake_case_symbol' do
      engine = Norikra::Engine.new(nil, nil)
      expect(engine.camelize(:symbol)).to eql('Symbol')
      expect(engine.camelize(:snake_case_symbol)).to eql('SnakeCaseSymbol')
    end
  end
end
