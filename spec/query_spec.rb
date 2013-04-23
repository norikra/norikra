require_relative './spec_helper'

require 'norikra/query'

describe Norikra::Query do
  context 'when instanciate' do
    describe '#initialize' do
      definition = {:service => 'string', :path => 'string', :duration => 'int'}
      typedef = Norikra::Typedef.new(:definition => definition)
      expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec)'

      context 'with typedef as hash' do
        subject { Norikra::Query.new(
            :name => 'TestTable query1', :tablename => 'TestTable', :typedef => definition, :expression => expression
        ) }

        its(:name){ should == 'TestTable query1' }
        its(:tablename){ should == 'TestTable' }
        its(:expression){ should == expression }
        its(:typedef){ should be_an_instance_of Norikra::Typedef }
      end

      context 'with typedef as instance of Norikra::Typedef' do
        subject { Norikra::Query.new(
            :name => 'TestTable query2', :tablename => 'TestTable', :typedef => typedef, :expression => expression
        ) }

        its(:typedef){ should equal(typedef) }
      end
    end
  end
end
