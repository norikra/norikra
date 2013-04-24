require_relative './spec_helper'

require 'norikra/query'

describe Norikra::Query do
  context 'when instanciate' do
    describe '#initialize' do
      expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec)'

      subject { Norikra::Query.new(
          :name => 'TestTable query1', :tablename => 'TestTable', :expression => expression
      ) }
      its(:name){ should == 'TestTable query1' }
      its(:tablename){ should == 'TestTable' }
      its(:expression){ should == expression }
    end
  end
end
