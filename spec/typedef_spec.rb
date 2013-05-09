require_relative './spec_helper'

require 'norikra/typedef'

require 'json'
require 'digest'

describe Norikra::Typedef do
  context 'has class method' do
    describe '.mangle_symbols' do
      it 'mangle symbol keys of parameter hash' do
        Norikra::Typedef.mangle_symbols({:a => 1, :b => 2}).should == {'a' => 1, 'b' => 2}
      end

      it 'reserve string keys as-is' do
        Norikra::Typedef.mangle_symbols({'a' => 1, :b => 2}).should == {'a' => 1, 'b' => 2}
      end
    end

    describe '.simple_guess' do
      it 'can guess field definitions with class of values' do
        t = Norikra::Typedef.simple_guess({'key1' => true, 'key2' => false, 'key3' => 10, 'key4' => 3.1415, 'key5' => 'foobar'})
        r = t.definition
        expect(r['key1']).to eql('boolean')
        expect(r['key2']).to eql('boolean')
        expect(r['key3']).to eql('long')
        expect(r['key4']).to eql('double')
        expect(r['key5']).to eql('string')
      end

      it 'does not guess with content of string values' do
        t = Norikra::Typedef.simple_guess({'key1' => 'TRUE', 'key2' => 'false', 'key3' => "10", 'key4' => '3.1415', 'key5' => {:a => 1}})
        r = t.definition
        expect(r['key1']).to eql('string')
        expect(r['key2']).to eql('string')
        expect(r['key3']).to eql('string')
        expect(r['key4']).to eql('string')
        expect(r['key5']).to eql('string')
      end
    end

    describe '.guess' do
      it 'can guess Boolean values and boolean-like strings as boolean correctly' do
        t = Norikra::Typedef.guess({'key1' => true, 'key2' => false, 'key3' => 'True', 'key4' => 'TRUE', 'key5' => 'false'})
        r = t.definition
        expect(r['key1']).to eql('boolean')
        expect(r['key2']).to eql('boolean')
        expect(r['key3']).to eql('boolean')
        expect(r['key4']).to eql('boolean')
        expect(r['key5']).to eql('boolean')
      end

      it 'can guess Float values and floating point number like strings as double correctly' do
        t = Norikra::Typedef.guess({'key1' => 0.1, 'key2' => 1.571, 'key3' => '1.571', 'key4' => '1.571e10', 'key5' => '-1.57e-5'})
        r = t.definition
        expect(r['key1']).to eql('double')
        expect(r['key2']).to eql('double')
        expect(r['key3']).to eql('double')
        expect(r['key4']).to eql('double')
        expect(r['key5']).to eql('double')
      end
      it 'can guess Integer values and int number like strings as long correctly' do
        t = Norikra::Typedef.guess({'key1' => 1, 'key2' => (2**32 + 1), 'key3' => '1024', 'key4' => '4294967297', 'key5' => '-3017'})
        r = t.definition
        expect(r['key1']).to eql('long')
        expect(r['key2']).to eql('long')
        expect(r['key3']).to eql('long')
        expect(r['key4']).to eql('long')
        expect(r['key5']).to eql('long')
      end
      it 'guess all non-boolean-float-integer values as string' do
        t = Norikra::Typedef.guess({'key1' => 'foo bar', 'key2' => '', 'key3' => nil, 'key4' => 'NULL', 'key5' => [1,2,3]})
        r = t.definition
        expect(r['key1']).to eql('string')
        expect(r['key2']).to eql('string')
        expect(r['key3']).to eql('string')
        expect(r['key4']).to eql('string')
        expect(r['key5']).to eql('string')
      end
    end
  end

  context 'when init' do
    describe '#initialize' do
      definition = {:service => 'string', :path => 'string', :duration => 'long'}

      context 'with name parameter' do
        subject { Norikra::Typedef.new(
            :name => 'test query 1', :definition => definition
        ) }
        its(:name) { should == 'test query 1' }
        its(:definition) { should == Norikra::Typedef.mangle_symbols(definition) }
      end

      context 'without name parameter' do
        subject { Norikra::Typedef.new(:definition => definition) }
        its(:definition) { should == Norikra::Typedef.mangle_symbols(definition) }
        key_sorted_definition = Norikra::Typedef.mangle_symbols(definition).sort{|a,b| a.first <=> b.first}
        its(:name) { should == Digest::MD5.hexdigest(key_sorted_definition.to_json) }
      end
    end
  end

  context 'when instanciated' do
    definition = {:service => 'string', :path => 'string', :duration => 'long', :rate => 'double'}
    typedef = Norikra::Typedef.new(:definition => definition)

    describe '#format' do
      context 'with data with valid content' do
        target1 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 33.0}
        target2 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => '33.0'}
        target3 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => 33}

        expected = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 33.0}
        not_expected = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 33}
        it 'returns converted data defined by typedef object' do
          expect(typedef.format(target1)).to eql(expected)
          expect(typedef.format(target1)['duration']).to be_kind_of(Integer)
          expect(typedef.format(target1)['rate']).to be_an_instance_of(Float)

          expect(typedef.format(target2)).to eql(expected)
          expect(typedef.format(target3)).to eql(expected)

          expect(typedef.format(target3)).to_not eql(not_expected)
        end
      end
    end

    describe '#match' do
      context 'with objects looks matches' do
        target1 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 0.33}
        target2 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => '0.33'}
        target3 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => 33}
        it 'returns true' do
          expect(typedef.match?(target1)).to be_true
          expect(typedef.match?(target2)).to be_true
          expect(typedef.match?(target3)).to be_true
        end
      end

      context 'with objects looks doesn\'t matches' do
        target1 = {'service' => 1.03, 'path' => '/path/to/data', 'duration' => 103200, 'rate' => '0.33'}
        target2 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 0.11, 'rate' => '0.33'}
        target3 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => '3handreds'}
        target4 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 'NULL'}
        it 'returns false' do
          expect(typedef.match?(target1)).to be_false
          expect(typedef.match?(target2)).to be_false
          expect(typedef.match?(target3)).to be_false
          expect(typedef.match?(target4)).to be_false
        end
      end
    end
  end

  context 'when instanciated through .guess' do
    describe '#match' do
      target1 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 0.33}
      target2 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => '0.33'}
      target3 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => 33}

      it 'returns true with self definition' do
        expect(Norikra::Typedef.guess(target1).match?(target1)).to be_true
        expect(Norikra::Typedef.guess(target2).match?(target2)).to be_true
        expect(Norikra::Typedef.guess(target3).match?(target3)).to be_true
      end
    end
  end
end
