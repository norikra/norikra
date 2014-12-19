require_relative './spec_helper'

require 'norikra/suspended_query'
require 'norikra/query'

include Norikra::SpecHelper

describe Norikra::SuspendedQuery do
  context 'when instanciate' do
    describe '#initialize' do
      it 'get query and just store its attributes' do
        q1 = Norikra::Query.new(name: 'name1', group: nil, expression: 'SELECT n,m FROM t')
        s1 = Norikra::SuspendedQuery.new(q1)
        expect(s1.name).to eql(q1.name)
        expect(s1.group).to eql(q1.group)
        expect(s1.expression).to eql(q1.expression)
        expect(s1.targets).to eql(q1.targets)

        expect(q1.suspended?).to be_falsy
        expect(s1.suspended?).to be_truthy

        q2 = Norikra::Query.new(name: 'name2', group: 'testing', expression: 'SELECT n,m,q.a FROM t, q')
        s2 = Norikra::SuspendedQuery.new(q2)
        expect(s2.name).to eql(q2.name)
        expect(s2.group).to eql(q2.group)
        expect(s2.expression).to eql(q2.expression)
        expect(s2.targets).to eql(q2.targets)

        expect(q2.suspended?).to be_falsy
        expect(s2.suspended?).to be_truthy
      end
    end

    describe '.<=>' do
      it 'returns sort order by group,name' do
        q1 = Norikra::Query.new(:name => '211', :group => 'a1', :expression => 'select x from y')
        q2 = Norikra::SuspendedQuery.new(Norikra::Query.new(:name => '111', :group => 'a1', :expression => 'select x from y'))
        q3 = Norikra::Query.new(:name => '011', :group => 'b1', :expression => 'select x from y')
        q4 = Norikra::Query.new(:name => '011', :group => 'a1', :expression => 'select x from y')
        q5 = Norikra::SuspendedQuery.new(Norikra::Query.new(:name => '999', :group => nil, :expression => 'select x from y'))
        q6 = Norikra::Query.new(:name => '899', :group => nil, :expression => 'select x from y')

        expect([q1,q2,q3,q4,q5,q6].sort).to eql([q6,q5,q4,q2,q1,q3])
      end

      it 'must be stable for sort' do
        q1 = Norikra::Query.new(name: "hoge", group: nil, expression: "select hoge from pos")
        s1 = Norikra::SuspendedQuery.new(q1)
        q2 = Norikra::Query.new(name: "test1", group: nil, expression: "select hoge,count(*)\r\nfrom pos\r\nwhere age >= 20\r\ngroup by hoge")
        s2 = Norikra::SuspendedQuery.new(q2)
        q3 = Norikra::Query.new(name: "test2", group: "sweep1", expression: "select moge\r\nfrom pos.win:time_batch(5 sec)\r\nwhere x=1\r\n")
        s3 = Norikra::SuspendedQuery.new(q3)
        expect([s1,s2,s3].sort).to eql([s1, s2, s3])
      end
    end

  end
end
