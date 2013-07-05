require_relative './spec_helper'

require 'norikra/query'

describe Norikra::Query do
  context 'when instanciate' do
    describe '#initialize' do
      context 'with simple query' do
        it 'returns query instances collectly parsed' do
          expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE path="/" AND size > 100 and param.length() > 0'
          q = Norikra::Query.new(
            :name => 'TestTable query1', :expression => expression
          )
          expect(q.name).to eql('TestTable query1')
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql(['param', 'path', 'size'].sort)
          expect(q.fields('TestTable')).to eql(['param','path','size'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with query including Static lib call' do
        it 'returns query instances collectly parsed' do
          expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) AS source WHERE source.path="/" AND Math.abs(-1 * source.size) > 3'
          q = Norikra::Query.new(
            :name => 'TestTable query2', :expression => expression
          )
          expect(q.name).to eql('TestTable query2')
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql(['path', 'size'].sort)
          expect(q.fields('TestTable')).to eql(['path', 'size'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with query with join' do
        it 'returns query instances collectly parsed' do
          expression = 'select product, max(sta.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 sec) as stb where sta.data.substr(0,8) = stb.header AND Math.abs(sta.size) > 3'
          q = Norikra::Query.new(
            :name => 'TestTable query3', :expression => expression
          )
          expect(q.name).to eql('TestTable query3')
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['StreamA', 'StreamB'])

          expect(q.fields).to eql(['product', 'size', 'data', 'header'].sort)
          expect(q.fields('StreamA')).to eql(['size','data'].sort)
          expect(q.fields('StreamB')).to eql(['size','header'].sort)
          expect(q.fields(nil)).to eql(['product'])
        end
      end

      context 'with query with subquery (where clause)' do
        it 'returns query instances collectly parsed' do
          expression = 'select * from RfidEvent as RFID where "Dock 1" = (select name from Zones.std:unique(zoneName) where zoneId = RFID.zoneId)'
          q = Norikra::Query.new(
            :name => 'TestTable query4', :expression => expression
          )
          expect(q.name).to eql('TestTable query4')
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['RfidEvent', 'Zones'])

          expect(q.fields).to eql(['name','zoneName','zoneId'].sort)
          expect(q.fields('RfidEvent')).to eql(['zoneId'])
          expect(q.fields('Zones')).to eql(['name','zoneName','zoneId'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with query with subquery (select clause)' do
        it 'returns query instances collectly parsed' do
          expression = 'select zoneId, (select name from Zones.std:unique(zoneName) where zoneId = RfidEvent.zoneId) as name from RfidEvent'
          q = Norikra::Query.new(
            :name => 'TestTable query5', :expression => expression
          )
          expect(q.name).to eql('TestTable query5')
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['RfidEvent', 'Zones'].sort)

          expect(q.fields).to eql(['name','zoneName','zoneId'].sort)
          expect(q.fields('RfidEvent')).to eql(['zoneId'])
          expect(q.fields('Zones')).to eql(['name','zoneName','zoneId'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with query with subquery (from clause)' do
        it 'returns query instances collectly parsed' do
          expression = "select * from BarData(ticker='MSFT', sub(closePrice, (select movAgv from SMA20Stream(ticker='MSFT').std:lastevent())) > 0)"
          q = Norikra::Query.new(
            :name => 'TestTable query6', :expression => expression
          )
          expect(q.name).to eql('TestTable query6')
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['BarData', 'SMA20Stream'].sort)

          expect(q.fields).to eql(['ticker','closePrice','movAgv'].sort)
          expect(q.fields('BarData')).to eql(['ticker','closePrice'].sort)
          expect(q.fields('SMA20Stream')).to eql(['movAgv','ticker'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end
    end

   describe '#dup_with_stream_name' do
      context 'with simple query' do
        expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE path="/" AND size > 100 and param.length() > 0'
        it 'returns duplicated object, with replaced ' do
          query = Norikra::Query.new(
            :name => 'TestTable query1', :expression => expression
          )
          expect(query.dup_with_stream_name('hoge').expression).to eql(
            'SELECT count(*) AS cnt FROM hoge.win:time_batch(10 sec) WHERE path="/" AND size > 100 and param.length() > 0'
          )
        end
      end

      context 'with query with newlines' do
        expression = <<EOQ
SELECT
  count(*) AS cnt
FROM TestTable.win:time_batch(10 sec)
WHERE path="/" AND size > 100
  AND param.length() > 0
EOQ
        expected_query = <<EOQ
SELECT
  count(*) AS cnt
FROM hoge.win:time_batch(10 sec)
WHERE path="/" AND size > 100
  AND param.length() > 0
EOQ
        it 'returns duplicated object, with replaced ' do
          query = Norikra::Query.new(
            :name => 'TestTable query1', :expression => expression
          )
          expect(query.dup_with_stream_name('hoge').expression).to eql(expected_query)
        end
      end
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
