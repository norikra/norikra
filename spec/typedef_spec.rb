require 'norikra/typedef'

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

    describe '.guess' do
      it 'can guess Boolean values and boolean-like strings as boolean correctly' do
        t = Norikra::Typedef.guess({'key1' => true, 'key2' => false, 'key3' => 'True', 'key4' => 'TRUE', 'key5' => 'false'})
        r = t.definition
        r['key1'].should eql('boolean')
        r['key2'].should eql('boolean')
        r['key3'].should eql('boolean')
        r['key4'].should eql('boolean')
        r['key5'].should eql('boolean')
      end

      it 'can guess Float values and floating point number like strings as double correctly' do
        t = Norikra::Typedef.guess({'key1' => 0.1, 'key2' => 1.571, 'key3' => '1.571', 'key4' => '1.571e10', 'key5' => '-1.57e-5'})
        r = t.definition
        r['key1'].should eql('double')
        r['key2'].should eql('double')
        r['key3'].should eql('double')
        r['key4'].should eql('double')
        r['key5'].should eql('double')
      end
      it 'can guess Integer values and int number like strings as long correctly' do
        t = Norikra::Typedef.guess({'key1' => 1, 'key2' => (2**32 + 1), 'key3' => '1024', 'key4' => '4294967297', 'key5' => '-3017'})
        r = t.definition
        r['key1'].should eql('long')
        r['key2'].should eql('long')
        r['key3'].should eql('long')
        r['key4'].should eql('long')
        r['key5'].should eql('long')
      end
      it 'guess all non-boolean-float-integer values as string' do
        t = Norikra::Typedef.guess({'key1' => 'foo bar', 'key2' => '', 'key3' => nil, 'key4' => 'NULL', 'key5' => [1,2,3]})
        r = t.definition
        r['key1'].should eql('string')
        r['key2'].should eql('string')
        r['key3'].should eql('string')
        r['key4'].should eql('string')
        r['key5'].should eql('string')
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
        its(:name) { should == Digest::MD5.hexdigest(Norikra::Typedef.mangle_symbols(definition).inspect) }
      end
    end
  end

  context 'when instanciated' do
    definition = {:service => 'string', :path => 'string', :duration => 'long', :rate => 'double'}
    typedef = Norikra::Typedef.new(:definition => definition)

    describe '#match' do
      context 'with objects looks matches' do
        target1 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 0.33}
        target2 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => '0.33'}
        target3 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => '103200', 'rate' => 33}
        it 'returns true' do
          typedef.match?(target1).should be_true
          typedef.match?(target2).should be_true
          typedef.match?(target3).should be_true
        end
      end

      context 'with objects looks doesn\'t matches' do
        target1 = {'service' => 1.03, 'path' => '/path/to/data', 'duration' => 103200, 'rate' => '0.33'}
        target2 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 0.11, 'rate' => '0.33'}
        target3 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => '3handreds'}
        target4 = {'service' => 'foobar', 'path' => '/path/to/data', 'duration' => 103200, 'rate' => 'NULL'}
        it 'returns false' do
          typedef.match?(target1).should be_false
          typedef.match?(target2).should be_false
          typedef.match?(target3).should be_false
          typedef.match?(target4).should be_false
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
        Norikra::Typedef.guess(target1).match?(target1).should be_true
        Norikra::Typedef.guess(target2).match?(target2).should be_true
        Norikra::Typedef.guess(target3).match?(target3).should be_true
      end
    end
  end
end
