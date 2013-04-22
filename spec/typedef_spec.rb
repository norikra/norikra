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
  end

  context 'when init' do
    describe '#initialize' do
      definition = {:service => 'string', :path => 'string', :duration => 'int'}

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
end
