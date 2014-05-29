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
        it 'will be ignored' do
          p = Norikra::OutputPool.new
          p.push('TestTable query1', nil, [])
          expect(p.pool).to eql({})
        end
      end

      context 'with event array' do
        it 'has pool with event' do
          pool = Norikra::OutputPool.new
          t = Time.now.to_i
          pool.push('TestTable query1',nil,[[t, {'count'=>1}],[t ,{'count'=>2}]])

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
    describe '#remove' do
      it 'remove query from pool, and from group-query mapping' do
        pool = Norikra::OutputPool.new
        t = Time.now.to_i
        pool.push('TestTable query1', 'group1', [[t,{'count'=>1}],[t,{'count'=>2}],[t,{'count'=>3}]])
        pool.push('TestTable query2', 'group2', [[t,{'count'=>4}]])

        pool.pop('TestTable query1')
        pool.remove('TestTable query1', 'group1')

        pool.push('TestTable query1', 'group3', [[t,{'count'=>1}],[t,{'count'=>2}],[t,{'count'=>3}]])

        r1 = pool.sweep('group1') #=> {}
        r3 = pool.sweep('group3')
        expect(r1['TestTable query1']).to be_nil
        expect(r3['TestTable query1'].size).to eql(3)
      end
    end

    describe '#pop' do
      it 'returns all events of specified query in pool' do
        pool = Norikra::OutputPool.new
        t = Time.now.to_i
        pool.push('TestTable query1', nil, [[t,{'count'=>1}],[t,{'count'=>2}]])
        pool.push('TestTable query2', nil, [[t,{'count'=>3}],[t,{'count'=>4}]])

        expect(pool.pop('TestTable query0').size).to eql(0)
        expect(pool.pop('TestTable query1').size).to eql(2)
        expect(pool.pool.size).to eql(1)
        expect(pool.pop('TestTable query1').size).to eql(0)
      end
    end

    describe '#sweep' do
      context 'with default query group' do
        it 'returns all events for all queries in pool' do
          pool = Norikra::OutputPool.new
          t = Time.now.to_i
          pool.push('TestTable query1', nil, [[t,{'count'=>1}],[t,{'count'=>2}]])
          pool.push('TestTable query2', nil, [[t,{'count'=>3}],[t,{'count'=>4}],[t,{'count'=>5}]])
          pool.push('TestTable query3', 'x', [[t,{'count'=>3}],[t,{'count'=>4}],[t,{'count'=>5}]])

          chunk = pool.sweep
          expect(chunk.keys.size).to eql(2)

          expect(chunk['TestTable query1'].size).to eql(2)
          expect(chunk['TestTable query2'].size).to eql(3)
          expect(chunk['TestTable query2'].last.last['count']).to eql(5)
        end
      end

      context 'with group specified' do
        it 'returns all events for all queries in pool' do
          pool = Norikra::OutputPool.new
          t = Time.now.to_i
          pool.push('TestTable query1', nil, [[t,{'count'=>1}],[t,{'count'=>2}]])
          pool.push('TestTable query2', nil, [[t,{'count'=>3}],[t,{'count'=>4}],[t,{'count'=>5}]])
          pool.push('TestTable query3', 'x', [[t,{'count'=>3}],[t,{'count'=>4}],[t,{'count'=>5}]])
          pool.push('TestTable query4', 'y', [[t,{'count'=>1}],[t,{'count'=>2}]])
          pool.push('TestTable query5', 'x', [[t,{'count'=>9}]])
          pool.push('TestTable query6', 'x', [[t,{'count'=>3}],[t,{'count'=>4}],[t,{'count'=>5}]])
          pool.push('TestTable query6', 'x', [[t,{'count'=>6}],[t,{'count'=>7}]])

          chunk = pool.sweep('x')
          expect(chunk.keys.size).to eql(3)

          expect(chunk['TestTable query3'].size).to eql(3)
          expect(chunk['TestTable query5'].size).to eql(1)
          expect(chunk['TestTable query6'].size).to eql(5)
        end
      end
    end
  end
end
