require_relative './spec_helper'

require 'norikra/query'

describe Norikra::Query do
  context 'when instanciate' do
    describe '#initialize' do
      context 'with simple query' do
        expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE path="/" AND size > 100 and param.length() > 0'
        subject { Norikra::Query.new(
            :name => 'TestTable query1', :tablename => 'TestTable', :expression => expression
        ) }
        its(:name){ should == 'TestTable query1' }
        its(:expression){ should == expression }
        its(:target){ should == 'TestTable' }
        its(:fields){ should == ['param', 'path', 'size'] }
      end
      context 'with query including Static lib call'
        expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE path="/" AND Math.abs(-1 * size) > 3'
        subject { Norikra::Query.new(
            :name => 'TestTable query1', :tablename => 'TestTable', :expression => expression
        ) }
        its(:name){ should == 'TestTable query1' }
        its(:expression){ should == expression }
        its(:target){ should == 'TestTable' }
        its(:fields){ should == ['path', 'size'] }
    end
  end
  describe '.imported_java_class?' do
    it 'can do judge passed name exists under java package tree or not' do
      expect(Norikra::Query.imported_java_class?('String')).to be_true
      expect(Norikra::Query.imported_java_class?('Long')).to be_true
      expect(Norikra::Query.imported_java_class?('Void')).to be_true
      expect(Norikra::Query.imported_java_class?('BigDecimal')).to be_true
      expect(Norikra::Query.imported_java_class?('Format')).to be_true
      expect(Norikra::Query.imported_java_class?('Normalizer')).to be_true
      expect(Norikra::Query.imported_java_class?('Date')).to be_true
      expect(Norikra::Query.imported_java_class?('HashSet')).to be_true
      expect(Norikra::Query.imported_java_class?('Random')).to be_true
      expect(Norikra::Query.imported_java_class?('Timer')).to be_true

      expect(Norikra::Query.imported_java_class?('unexpected')).to be_false
      expect(Norikra::Query.imported_java_class?('parameter')).to be_false
      expect(Norikra::Query.imported_java_class?('param')).to be_false
    end
  end
end
