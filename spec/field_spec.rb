require_relative './spec_helper'

require 'norikra/typedef'

require 'json'
require 'digest'

describe Norikra::Field do
  describe '.valid_type?' do
    it 'returns normalized type strings' do
      expect(Norikra::Field.valid_type?('String')).to eql('string')
      expect(Norikra::Field.valid_type?('STRING')).to eql('string')
      expect(Norikra::Field.valid_type?(:string)).to eql('string')
      expect(Norikra::Field.valid_type?('string')).to eql('string')

      expect(Norikra::Field.valid_type?('boolean')).to eql('boolean')
      expect(Norikra::Field.valid_type?('BOOLEAN')).to eql('boolean')
      expect(Norikra::Field.valid_type?('Int')).to eql('int')
      expect(Norikra::Field.valid_type?('lonG')).to eql('long')
      expect(Norikra::Field.valid_type?('FLOAT')).to eql('float')
      expect(Norikra::Field.valid_type?('Double')).to eql('double')
    end

    it 'raises ArgumentError for unknown type string' do
      expect { Norikra::Field.valid_type?('foo') }.to raise_error(ArgumentError)
    end
  end

  context 'when initialized' do
    it 'value of field name is normalized to string' do
      expect(Norikra::Field.new('foo', 'string').name).to be_instance_of String
      expect(Norikra::Field.new(:foo, 'string').name).to be_instance_of String
    end

    it 'value of type is normalized with .valid_type?' do
      expect(Norikra::Field.new('foo', 'String').type).to eql(Norikra::Field.valid_type?('String'))
    end

    it 'default value of optional is nil' do
      expect(Norikra::Field.new(:foo, 'String').optional).to be_nil
    end
  end

  context 'has non-nil value for optional' do
    describe '#dup' do
      context 'without values' do
        it 'saves original boolean value' do
          f = Norikra::Field.new('foo', 'string', false)
          expect(f.dup.optional).to eql(false)

          f = Norikra::Field.new('foo', 'int', true)
          expect(f.dup.optional).to eql(true)
        end
      end

      context 'with value' do
        it 'will be overwritten with specified value' do
          f = Norikra::Field.new('bar', 'float', false)
          expect(f.dup(true).optional).to eql(true)

          f = Norikra::Field.new('bar', 'double', true)
          expect(f.dup(false).optional).to eql(false)
        end
      end
    end
  end

  context 'defined as string field' do
    describe '#format' do
      it 'converts specified value as string' do
        f = Norikra::Field.new('x', 'string')
        expect(f.format('foo bar')).to eql('foo bar')
        expect(f.format('foo bar'.to_sym)).to eql('foo bar')
        expect(f.format(500)).to eql('500')
        expect(f.format(' ')).to eql(' ')
        expect(f.format(true)).to eql('true')
        expect(f.format(false)).to eql('false')
        expect(f.format(nil)).to eql('')
        expect(f.format({})).to eql('{}')
        expect(f.format([])).to eql('[]')
      end
    end
  end

  context 'defined as boolean' do
    describe '#format' do
      it 'converts specified value as boolean' do
        f = Norikra::Field.new('x', 'boolean')
        expect(f.format(true)).to eql(true)
        expect(f.format(false)).to eql(false)
        expect(f.format(nil)).to eql(false)
        expect(f.format('')).to eql(true)

        expect(f.format('true')).to eql(true)
        expect(f.format('false')).to eql(false)
      end
    end
  end

  context 'defined as numeric value (int/long/float/double)' do
    describe '#format' do
      it 'convertes specified value as numeric' do
        f = Norikra::Field.new('x', 'int')
        expect(f.format('1')).to eql(1)
        expect(f.format('1.0')).to eql(1)
        expect(f.format('0.1')).to eql(0)
        expect(f.format('.1')).to eql(0)
        expect(f.format('')).to eql(0)
        expect(f.format(' ')).to eql(0)
        expect(f.format(nil)).to eql(0)

        f = Norikra::Field.new('x', 'long')
        expect(f.format('1')).to eql(1)
        expect(f.format('1.0')).to eql(1)
        expect(f.format('0.1')).to eql(0)
        expect(f.format('.1')).to eql(0)
        expect(f.format('')).to eql(0)
        expect(f.format(' ')).to eql(0)
        expect(f.format(nil)).to eql(0)

        f = Norikra::Field.new('x', 'float')
        expect(f.format('1')).to eql(1.0)
        expect(f.format('1.0')).to eql(1.0)
        expect(f.format('0.1')).to eql(0.1)
        expect(f.format('.1')).to eql(0.1)
        expect(f.format('')).to eql(0.0)
        expect(f.format(' ')).to eql(0.0)
        expect(f.format(nil)).to eql(0.0)

        f = Norikra::Field.new('x', 'double')
        expect(f.format('1')).to eql(1.0)
        expect(f.format('1.0')).to eql(1.0)
        expect(f.format('0.1')).to eql(0.1)
        expect(f.format('.1')).to eql(0.1)
        expect(f.format('')).to eql(0.0)
        expect(f.format(' ')).to eql(0.0)
        expect(f.format(nil)).to eql(0.0)
      end
    end
  end
end
