require_relative './spec_helper'

require 'norikra/output_pool'

describe Norikra::OutputPool do
  context 'without any events in pool' do
    describe '#pop' do
      it 'returns blank array' do
        subject.pop('TestTable query1').should == []
      end
    end

    describe '#push' do
      context 'with empty array' do
        subject { p = Norikra::OutputPool.new; p.push('TestTable query1', []); p }
        its(:pool){ should == {'TestTable query1' => []} }
      end

      context 'with event array' do
        it 'has pool with event' do
          pool = Norikra::OutputPool.new
          t = Time.now.to_i
          pool.push('TestTable query1', [{'count'=>1},{'count'=>2}])

          pool.pool.keys.should eql(['TestTable query1'])
          events = pool.pool['TestTable query1']

          events.size.should eql(2)

          (t..(t+1)).should cover(events[0].first) # time
          events[0].last.should eql({'count'=>1})

          (t..(t+1)).should cover(events[1].first) # time
          events[1].first.should eql(events[0].first)
          events[1].last.should eql({'count'=>2})
        end
      end
    end
  end

  context 'with events in pool' do
    describe '#pop' do
      it 'returns all events of specified table in pool' do
        pool = Norikra::OutputPool.new
        t = Time.now.to_i
        pool.push('TestTable query1', [{'count'=>1},{'count'=>2}])
        pool.push('TestTable query2', [{'count'=>3},{'count'=>4}])

        pool.pop('TestTable query0').size.should eql(0)
        pool.pop('TestTable query1').size.should eql(2)
        pool.pool.size.should eql(1)
        pool.pop('TestTable query1').size.should eql(0)
      end
    end
  end
end
