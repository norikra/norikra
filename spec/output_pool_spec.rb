require_relative './spec_helper'

require 'norikra/output_pool'

describe Norikra::OutputPool do
  context 'without any events in pool' do
    describe '#pop' do
      it 'returns blank array' do
        expect(subject.pop('TestTable query1')).to eql([])
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

          expect(events.size).to eq(1) # pool event bucket size is equal to times of #push
          expect(events.first.size).to eq(2) # bucket size if equal to event num of #push

          bucket = events.first

          expect(t..(t+1)).to cover(bucket[0].first) # time
          expect(bucket[0].last).to eql({'count'=>1})

          expect(t..(t+1)).to cover(bucket[1].first) # time
          expect(bucket[1].first).to eql(bucket[0].first)
          expect(bucket[1].last).to eql({'count'=>2})
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

        expect(pool.pop('TestTable query0').size).to eql(0)
        expect(pool.pop('TestTable query1').size).to eql(2)
        expect(pool.pool.size).to eql(1)
        expect(pool.pop('TestTable query1').size).to eql(0)
      end
    end
  end
end
