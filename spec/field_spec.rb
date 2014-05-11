# -*- coding: utf-8 -*-
require_relative './spec_helper'

require 'norikra/field'

require 'json'
require 'digest'

describe Norikra::Field do
  describe '.escape_name' do
    it 'escapes chars not alphabetic and numeric chars, with "_"' do
      expect(Norikra::Field.escape_name("part1 part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1^part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1|part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1\"part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1'part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1@part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1#part2")).to eql('part1_part2')
      expect(Norikra::Field.escape_name("part1あpart2")).to eql('part1_part2')
    end

    it 'escape "." in field name with "$"' do
      expect(Norikra::Field.escape_name("part1.part2")).to eql('part1$part2')
    end

    it 'escape additional "." which specify string-dot of key chain escaped with "_"' do
      expect(Norikra::Field.escape_name("part1..part2")).to eql('part1$_part2')
    end

    it 'escape numeric-only part with prefix "$"' do
      expect(Norikra::Field.escape_name("part1.0")).to eql('part1$$0')
    end
  end

  describe '.unescape_name' do
    it 're_make dotted pattern fieldname for container access chain' do
      expect(Norikra::Field.unescape_name("part1$part2")).to eql('part1.part2')
      expect(Norikra::Field.unescape_name("part1$$0")).to eql('part1.$0')
      expect(Norikra::Field.unescape_name("part1$$$0")).to eql('part1.$$0')
    end
  end

  describe '.regulate_key_chain' do
    it 'escape String chain items and returns by array which started with numeric, with "$$", and joins keys with separator "$"' do
      expect(Norikra::Field.regulate_key_chain(["part1", "part2"])).to eql(['part1','part2'])
      expect(Norikra::Field.regulate_key_chain(["part.1", "2"])).to eql(['part_1', '$$2'])
      expect(Norikra::Field.regulate_key_chain(["part1", 2])).to eql(['part1', '$2'])
      expect(Norikra::Field.regulate_key_chain(["part1", 2, "2"])).to eql(['part1', '$2', '$$2'])
      expect(Norikra::Field.regulate_key_chain(["part1", ".part2"])).to eql(['part1', '_part2'])
      expect(Norikra::Field.regulate_key_chain(["part1", 2, ".part2"])).to eql(['part1', '$2', '_part2'])
    end
  end

  describe '.escape_key_chain' do
    it 'escape String chain items which started with numeric, with "$$", and joins keys with separator "$"' do
      expect(Norikra::Field.escape_key_chain("part1", "part2")).to eql('part1$part2')
      expect(Norikra::Field.escape_key_chain("part.1", "2")).to eql('part_1$$$2')
      expect(Norikra::Field.escape_key_chain("part1", 2)).to eql('part1$$2')
      expect(Norikra::Field.escape_key_chain("part1", 2, "2")).to eql('part1$$2$$$2')
      expect(Norikra::Field.escape_key_chain("part1", ".part2")).to eql('part1$_part2')
      expect(Norikra::Field.escape_key_chain("part1", 2, ".part2")).to eql('part1$$2$_part2')
    end
  end

  describe '.container_type?' do
    it 'returns true for only "hash" and "array"' do
      expect(Norikra::Field.container_type?('')).to be_false
      expect(Norikra::Field.container_type?('string')).to be_false
      expect(Norikra::Field.container_type?('int')).to be_false
      expect(Norikra::Field.container_type?('long')).to be_false

      expect(Norikra::Field.container_type?('Hash')).to be_true
      expect(Norikra::Field.container_type?('hash')).to be_true
      expect(Norikra::Field.container_type?('Array')).to be_true
      expect(Norikra::Field.container_type?('array')).to be_true
    end
  end

  describe '.valid_type' do
    it 'returns normalized type strings' do
      expect(Norikra::Field.valid_type('String')).to eql('string')
      expect(Norikra::Field.valid_type('STRING')).to eql('string')
      expect(Norikra::Field.valid_type(:string)).to eql('string')
      expect(Norikra::Field.valid_type('string')).to eql('string')

      expect(Norikra::Field.valid_type('boolean')).to eql('boolean')
      expect(Norikra::Field.valid_type('BOOLEAN')).to eql('boolean')
      expect(Norikra::Field.valid_type('Int')).to eql('integer')
      expect(Norikra::Field.valid_type('lonG')).to eql('integer')
      expect(Norikra::Field.valid_type('FLOAT')).to eql('float')
      expect(Norikra::Field.valid_type('Double')).to eql('float')
    end

    it 'raises ArgumentError for unknown type string' do
      expect { Norikra::Field.valid_type('foo') }.to raise_error(Norikra::ArgumentError)
    end
  end

  context 'when initialized' do
    it 'value of field name is normalized to string' do
      expect(Norikra::Field.new('foo', 'string').name).to be_instance_of String
      expect(Norikra::Field.new(:foo, 'string').name).to be_instance_of String
    end

    it 'value of type is normalized with .valid_type?' do
      expect(Norikra::Field.new('foo', 'String').type).to eql(Norikra::Field.valid_type('String'))
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

        expect(f.format(nil)).to be_nil
        expect(f.format({})).to be_nil
        expect(f.format([])).to be_nil
      end
    end
  end

  context 'defined as boolean' do
    describe '#format' do
      it 'converts specified value as boolean' do
        f = Norikra::Field.new('x', 'boolean')
        expect(f.format(true)).to eql(true)
        expect(f.format(false)).to eql(false)
        expect(f.format('')).to eql(true)

        expect(f.format('true')).to eql(true)
        expect(f.format('false')).to eql(false)

        expect(f.format(nil)).to be_nil
        expect(f.format({})).to be_nil
        expect(f.format([])).to be_nil
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
        expect(f.format(nil)).to be_nil
        expect(f.format({})).to be_nil
        expect(f.format([])).to be_nil

        f = Norikra::Field.new('x', 'long')
        expect(f.format('1')).to eql(1)
        expect(f.format('1.0')).to eql(1)
        expect(f.format('0.1')).to eql(0)
        expect(f.format('.1')).to eql(0)
        expect(f.format('')).to eql(0)
        expect(f.format(' ')).to eql(0)
        expect(f.format(nil)).to be_nil
        expect(f.format({})).to be_nil
        expect(f.format([])).to be_nil

        f = Norikra::Field.new('x', 'float')
        expect(f.format('1')).to eql(1.0)
        expect(f.format('1.0')).to eql(1.0)
        expect(f.format('0.1')).to eql(0.1)
        expect(f.format('.1')).to eql(0.1)
        expect(f.format('')).to eql(0.0)
        expect(f.format(' ')).to eql(0.0)
        expect(f.format(nil)).to be_nil
        expect(f.format({})).to be_nil
        expect(f.format([])).to be_nil

        f = Norikra::Field.new('x', 'double')
        expect(f.format('1')).to eql(1.0)
        expect(f.format('1.0')).to eql(1.0)
        expect(f.format('0.1')).to eql(0.1)
        expect(f.format('.1')).to eql(0.1)
        expect(f.format('')).to eql(0.0)
        expect(f.format(' ')).to eql(0.0)
        expect(f.format(nil)).to be_nil
        expect(f.format({})).to be_nil
        expect(f.format([])).to be_nil
      end
    end
  end

  describe '#define_value_accessor' do
    it 'defines value accessor method for simple single field name' do
      f = Norikra::Field.new('foo', 'string')

      f.define_value_accessor('foo', false)
      expect(f.value({'foo' => 'value1', 'bar' => 'value2', 'baz' => 'value3'})).to eql('value1')
    end

    it 'defines chain value accessor for 2-depth hash access chain' do
      f = Norikra::Field.new('foo', 'hash')
      f.define_value_accessor('foo.bar', true)
      expect(f.value({'foo' => {'bar' => 'value1'}, 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => ['value1'], 'bar' => 'value2'})).to be_nil
      expect(f.value({'foo' => 'value1', 'bar' => 'value2'})).to be_nil
    end

    it 'defines chain value accessor for 2-depth array access chain' do
      f = Norikra::Field.new('foo', 'array')
      f.define_value_accessor('foo.0', true)
      expect(f.value({'foo' => {'bar' => 'value1'}, 'bar' => 'value2'})).to be_nil
      expect(f.value({'foo' => ['value1'], 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => 'value1', 'bar' => 'value2'})).to be_nil
    end

    it 'defines chain value accessor for 2-depth array access chain' do
      f = Norikra::Field.new('foo', 'array')
      f.define_value_accessor('foo.$0', true)
      expect(f.value({'foo' => {0 => 'value1'}, 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => {'bar' => 'value1'}, 'bar' => 'value2'})).to be_nil
      expect(f.value({'foo' => ['value1'], 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => 'value1', 'bar' => 'value2'})).to be_nil
    end

    it 'defines chain value accessor for 2-depth hash access chain, with numeric string' do
      f = Norikra::Field.new('foo', 'hash')
      f.define_value_accessor('foo.$$0', true)
      expect(f.value({'foo' => {0 => 'value1'}, 'bar' => 'value2'})).to be_nil
      expect(f.value({'foo' => {'0' => 'value1'}, 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => ['value1'], 'bar' => 'value2'})).to be_nil
      expect(f.value({'foo' => 'value1', 'bar' => 'value2'})).to be_nil
    end

    it 'defines chain value accessor for 2-depth access chain, with integer key' do
      f = Norikra::Field.new('foo', 'hash')
      f.define_value_accessor('foo.0', true)
      expect(f.value({'foo' => {0 => 'value1'}, 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => {'0' => 'value1'}, 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => ['value1'], 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => 'value1', 'bar' => 'value2'})).to be_nil
    end

    it 'defines chain value accessor for 2-depth chain with dots' do
      f = Norikra::Field.new('foo', 'hash')
      f.define_value_accessor('foo..data', true)
      expect(f.value({'foo' => {'.data' => 'value1'}, 'bar' => 'value2'})).to eql('value1')
      expect(f.value({'foo' => ['value1'], 'bar' => 'value2'})).to be_nil
      expect(f.value({'foo' => 'value1', 'bar' => 'value2'})).to be_nil
    end

    it 'defines chain value accessor for N-depth hash and array' do
      f = Norikra::Field.new('foo', 'hash')
      f.define_value_accessor('foo.bar.$0.baz', true)
      expect(f.value({'foo' => {'bar' => [{'baz' => 'value1'}, {'baz' => 'value2'}]}})).to eql('value1')
      f.define_value_accessor('foo.bar.1.baz', true)
      expect(f.value({'foo' => {'bar' => [{'baz' => 'value1'}, {'baz' => 'value2'}]}})).to eql('value2')
    end

    it 'defines chain value accessor with field name including escaped field' do
      f = Norikra::Field.new('foo', 'hash')
      f.define_value_accessor('foo.bar_baz.bar_baz', true)
      data = {
        'foo' => {
          'bar baz' => {
            'bar/baz' => 'ichi',
          }
        }
      }
      expect(f.value(data)).to eql('ichi')
    end
  end
end
