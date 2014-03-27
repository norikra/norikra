require_relative './spec_helper'

require 'norikra/query'

include Norikra::SpecHelper

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
          expect(q.group).to be_nil
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql(['param', 'path', 'size'].sort)
          expect(q.fields('TestTable')).to eql(['param','path','size'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with top-level built-in functions' do
        it 'returns query instances collectly parsed' do
          expression = 'SELECT rate(10) FROM TestTable output snapshot every 2 sec'
          q = Norikra::Query.new(
            :name => 'TestTable query1', :expression => expression
          )
          expect(q.name).to eql('TestTable query1')
          expect(q.group).to be_nil
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql([])
          expect(q.fields('TestTable')).to eql([])
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with order by' do
        it 'returns query instances, collectly parsed, without AS_names for fields' do
          expression = 'SELECT name.string, count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE path="/" AND size > 100 and param.length() > 0 GROUP BY name.string ORDER BY cnt'
          q = Norikra::Query.new(
            :name => 'TestTable query1', :expression => expression
          )
          expect(q.name).to eql('TestTable query1')
          expect(q.group).to be_nil
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql(['name.string', 'param', 'path', 'size'].sort)
          expect(q.fields('TestTable')).to eql(['name.string', 'param','path','size'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with query including Static lib call' do
        it 'returns query instances collectly parsed' do
          expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) AS source WHERE source.path="/" AND Math.abs(-1 * source.size) > 3'
          q = Norikra::Query.new(
            :name => 'TestTable query2', :group => 'label1', :expression => expression
          )
          expect(q.name).to eql('TestTable query2')
          expect(q.group).to eql('label1')
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

      context 'with simple query including container field accesses' do
        it 'returns query instances collectly parsed' do
          expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE params.path="/" AND size > 100 and opts.$0 > 0'
          q = Norikra::Query.new(
            :name => 'TestTable query7', :expression => expression
          )
          expect(q.name).to eql('TestTable query7')
          expect(q.group).to be_nil
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql(['params.path', 'size', 'opts.$0'].sort)
          expect(q.fields('TestTable')).to eql(['params.path', 'size', 'opts.$0'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with simple query including deep depth container field accesses and function calls' do
        it 'returns query instances collectly parsed' do
          expression = 'SELECT count(*) AS cnt FROM TestTable.win:time_batch(10 sec) WHERE params.$$path.$1="/" AND size.$0.bytes > 100 and opts.num.$0.length() > 0'
          q = Norikra::Query.new(
            :name => 'TestTable query8', :expression => expression
          )
          expect(q.name).to eql('TestTable query8')
          expect(q.group).to be_nil
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['TestTable'])

          expect(q.fields).to eql(['params.$$path.$1', 'size.$0.bytes', 'opts.num.$0'].sort)
          expect(q.fields('TestTable')).to eql(['params.$$path.$1', 'size.$0.bytes', 'opts.num.$0'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end

      context 'with query with patterns' do
        it 'returns query instances collectly parsed' do

          expression = "select a.name, a.content, b.content from pattern [every a=EventA -> b=EventA(name = a.name, type = 'TYPE') where timer:within(1 min)].win:time(2 hour) where a.source in ('A', 'B')"
          q = Norikra::Query.new(
            :name => 'TestTable query9', :expression => expression
          )
          expect(q.name).to eql('TestTable query9')
          expect(q.group).to be_nil
          expect(q.expression).to eql(expression)
          expect(q.targets).to eql(['EventA'])
          expect(q.aliases).to eql(['a', 'b'])
          expect(q.fields).to eql(['name', 'content', 'type', 'source'].sort)
          expect(q.fields('EventA')).to eql(['name', 'content', 'type', 'source'].sort)
          expect(q.fields(nil)).to eql([])
        end
      end
    end

    describe '#dup' do
      context 'for queries without group (default group)' do
        it 'returns query object with default group' do
          e1 = 'SELECT max(num) AS max FROM TestTable1.win:time(5 sec)'
          query = Norikra::Query.new(:name => 'q1', :group => nil, :expression => e1)
          q = query.dup
          expect(q.name).to eql('q1')
          expect(q.group).to be_nil
          expect(q.expression).to eql(e1)
        end
      end

      context 'for queries with group' do
        it 'returns query object with specified group' do
          e2 = 'SELECT max(num) AS max FROM TestTable2.win:time(5 sec)'
          query = Norikra::Query.new(:name => 'q2', :group => 'g2', :expression => e2)
          q = query.dup
          expect(q.name).to eql('q2')
          expect(q.group).to eql('g2')
          expect(q.expression).to eql(e2)
        end
      end
    end

    describe '.rewrite_event_field_name' do
      context 'without any container field access' do
        expression = 'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and size > 100 and (param.length()) > 0'
        it 'returns same query with original' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_field_name(model, {'TestTable' => 'T1'}).toEPL).to eql(expression)
          end
        end
      end

      context 'with container field access' do
        expression = 'select max(result.$0.size) as cnt from TestTable.win:time_batch(10 seconds) where req.path = "/" and result.$0.size > 100 and (req.param.length()) > 0'
        expected   = 'select max(result$$0$size) as cnt from TestTable.win:time_batch(10 seconds) where req$path = "/" and result$$0$size > 100 and (req$param.length()) > 0'
        it 'returns query with encoded container fields' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_field_name(model, {'TestTable' => 'T1'}).toEPL).to eql(expected)
          end
        end
      end

      context 'with container field access with joins' do
        expression = 'select product, max(sta.param.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data.$0.$$body.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
        expected   = 'select product, max(sta.param$size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data$$0$$$body.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
        it 'returns query with encoded container fields' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_field_name(model, {'StreamA' => 'S1', 'StreamB' => 'S2'}).toEPL).to eql(expected)
          end
        end
      end

      context 'without any container field access, but with alias specification, without joins' do
        expression = 'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and TestTable.size > 100 and (param.length()) > 0'
        expected =   'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and T1.size > 100 and (param.length()) > 0'
        it 'returns query expression' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_field_name(model, {'TestTable' => 'T1'}).toEPL).to eql(expected)
          end
        end
      end

      context 'with subquery in select clause' do
        expression = 'select RfidEvent.zoneId.$0, (select name.x from Zones.std:unique(zoneName) where zoneId = RfidEvent.zoneId.$0) as name from RfidEvent'
        expected   = 'select Z2.zoneId$$0, (select name$x from Zones.std:unique(zoneName) where zoneId = Z2.zoneId$$0) as name from RfidEvent'
        it 'returns query model which have replaced stream name, for only targets of fully qualified field name access' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_field_name(model, {'Zones' => 'Z1', 'RfidEvent' => 'Z2'}).toEPL).to eql(expected)
          end
        end
      end

      context 'with container field accesses, with targets, aliases and joins' do
        expression = 'select StreamA.product, max(sta.param.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data.$0.$$body.substr(0, 8)) = StreamB.header.$0 and (Math.abs(StreamA.size.$0.$$abs)) > 3'
        expected   = 'select S1.product, max(sta.param$size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data$$0$$$body.substr(0, 8)) = S2.header$$0 and (Math.abs(S1.size$$0$$$abs)) > 3'
        it 'returns query model which have replaced stream name, for only targets of fully qualified field name access' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_field_name(model, {'StreamA' => 'S1', 'StreamB' => 'S2'}).toEPL).to eql(expected)
          end
        end
      end
    end

    describe '.rewrite_event_type_name' do
      context 'with simple query' do
        expression = 'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and size > 100 and (param.length()) > 0'

        it 'returns query model which have replaced stream name' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_type_name(model, {'TestTable' => 'hoge'}).toEPL).to eql(expression.sub('TestTable','hoge'))
          end
        end
      end
      context 'with subquery in select clause' do
        expression = 'select zoneId.$0, (select name.x from Zones.std:unique(zoneName) where zoneId = RfidEvent.zoneId.$0) as name from RfidEvent'
        expected   = 'select zoneId.$0, (select name.x from Z1.std:unique(zoneName) where zoneId = RfidEvent.zoneId.$0) as name from Z2'
        it 'returns query model which have replaced stream name, for only From clause' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_type_name(model, {'Zones' => 'Z1', 'RfidEvent' => 'Z2'}).toEPL).to eql(expected)
          end
        end
      end
      context 'with subquery in from clause' do
        expression = "select * from BarData(ticker='MSFT', sub(closePrice, (select movAgv from SMA20Stream(ticker='MSFT').std:lastevent())) > 0)"
        expected   = 'select * from B1(ticker = "MSFT" and (sub(closePrice, (select movAgv from B2(ticker = "MSFT").std:lastevent()))) > 0)'
        it 'returns query model which have replaced stream name' do
          with_engine do
            model = administrator.compileEPL(expression)
            expect(Norikra::Query.rewrite_event_type_name(model, {'BarData' => 'B1', 'SMA20Stream' => 'B2'}).toEPL).to eql(expected)
          end
        end
      end
      context 'with joins' do
        expression = 'select product, max(sta.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
        it 'returns query model which have replaced stream name' do
          with_engine do
            model = administrator.compileEPL(expression)
            mapping = {'StreamA' => 'sa', 'StreamB' => 'sb'}
            expect(Norikra::Query.rewrite_event_type_name(model, mapping).toEPL).to eql(expression.sub('StreamA','sa').sub('StreamB','sb'))
          end
        end
      end
    end

    describe '.rewrite_query' do
      it 'rewrites all of targets and container-field-accesses' do
        with_engine do
          e1 = 'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and size > 100 and (param.length()) > 0'
          x1 = 'select count(*) as cnt from T1.win:time_batch(10 seconds) where path = "/" and size > 100 and (param.length()) > 0'
          model = administrator.compileEPL(e1)
          mapping = {'TestTable' => 'T1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x1)

          e2 = 'select max(result.$0.size) as cnt from TestTable.win:time_batch(10 seconds) where req.path = "/" and result.$0.size > 100 and (req.param.length()) > 0'
          x2 = 'select max(result$$0$size) as cnt from T1.win:time_batch(10 seconds) where req$path = "/" and result$$0$size > 100 and (req$param.length()) > 0'
          model = administrator.compileEPL(e2)
          mapping = {'TestTable' => 'T1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x2)

          e3 = 'select product, max(sta.param.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data.$0.$$body.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
          x3 = 'select product, max(sta.param$size) as maxsize from S1.win:keepall() as sta, S2(size > 10).win:time(20 seconds) as stb where (sta.data$$0$$$body.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
          model = administrator.compileEPL(e3)
          mapping = {'StreamA' => 'S1', 'StreamB' => 'S2'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x3)

          e4 = 'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and TestTable.size > 100 and (param.length()) > 0'
          x4 = 'select count(*) as cnt from T1.win:time_batch(10 seconds) where path = "/" and T1.size > 100 and (param.length()) > 0'
          model = administrator.compileEPL(e4)
          mapping = {'TestTable' => 'T1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x4)

          e5 = 'select RfidEvent.zoneId.$0, (select name.x from Zones.std:unique(zoneName) where zoneId = RfidEvent.zoneId.$0) as name from RfidEvent'
          x5 = 'select R1.zoneId$$0, (select name$x from Z1.std:unique(zoneName) where zoneId = R1.zoneId$$0) as name from R1'
          model = administrator.compileEPL(e5)
          mapping = {'RfidEvent' => 'R1', 'Zones' => 'Z1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x5)

          e6 = 'select StreamA.product, max(sta.param.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data.$0.$$body.substr(0, 8)) = StreamB.header.$0 and (Math.abs(StreamA.size.$0.$$abs)) > 3'
          x6 = 'select S1.product, max(sta.param$size) as maxsize from S1.win:keepall() as sta, S2(size > 10).win:time(20 seconds) as stb where (sta.data$$0$$$body.substr(0, 8)) = S2.header$$0 and (Math.abs(S1.size$$0$$$abs)) > 3'
          model = administrator.compileEPL(e6)
          mapping = {'StreamA' => 'S1', 'StreamB' => 'S2'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x6)

          e7 = 'select count(*) as cnt from TestTable.win:time_batch(10 seconds) where path = "/" and size > 100 and (param.length()) > 0'
          x7 = 'select count(*) as cnt from T1.win:time_batch(10 seconds) where path = "/" and size > 100 and (param.length()) > 0'
          model = administrator.compileEPL(e7)
          mapping = {'TestTable' => 'T1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x7)

          e8 = 'select RfidEvent.zoneId.$0, (select name.x from Zones.std:unique(zoneName) where zoneId = RfidEvent.zoneId.$0) as name from RfidEvent'
          x8 = 'select R1.zoneId$$0, (select name$x from Z1.std:unique(zoneName) where zoneId = R1.zoneId$$0) as name from R1'
          model = administrator.compileEPL(e8)
          mapping = {'Zones' => 'Z1', 'RfidEvent' => 'R1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x8)

          e9 = 'select * from BarData(ticker = "MSFT" and (sub(closePrice, (select movAgv from SMA20Stream(ticker = "MSFT").std:lastevent())) > 0))'
          x9 = 'select * from B1(ticker = "MSFT" and (sub(closePrice, (select movAgv from S1(ticker = "MSFT").std:lastevent()))) > 0)'
          model = administrator.compileEPL(e9)
          mapping = {'BarData' => 'B1', 'SMA20Stream' => 'S1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x9)

          e10 = 'select product, max(sta.size) as maxsize from StreamA.win:keepall() as sta, StreamB(size > 10).win:time(20 seconds) as stb where (sta.data.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
          x10 = 'select product, max(sta.size) as maxsize from S1.win:keepall() as sta, S2(size > 10).win:time(20 seconds) as stb where (sta.data.substr(0, 8)) = stb.header and (Math.abs(sta.size)) > 3'
          model = administrator.compileEPL(e10)
          mapping = {'StreamA' => 'S1', 'StreamB' => 'S2'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x10)

          # GROUP BY clause
          e11 = 'select applog.campaign.id as campaign_id, member.region as region, member.lang as lang, count(*) as click, count(distinct member.id) as uu from applog.win:time_batch(1 minutes) where type = "click" group by applog.campaign.id, member.region, member.lang'
          x11 = 'select A1.campaign$id as campaign_id, member$region as region, member$lang as lang, count(*) as click, count(distinct member$id) as uu from A1.win:time_batch(1 minutes) where type = "click" group by A1.campaign$id, member$region, member$lang'
          model = administrator.compileEPL(e11)
          mapping = {'applog' => 'A1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x11)

          # ORDER BY clause
          e12 = 'select campaign.id, member.region as region, member.lang as lang, count(*) as click, count(distinct member.id) as uu from applog.win:time_batch(1 minutes) where type = "click" group by campaign.id, member.region, member.lang order by campaign.id'
          x12 = 'select campaign$id, member$region as region, member$lang as lang, count(*) as click, count(distinct member$id) as uu from A1.win:time_batch(1 minutes) where type = "click" group by campaign$id, member$region, member$lang order by campaign$id'
          model = administrator.compileEPL(e12)
          mapping = {'applog' => 'A1'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x12)

          # HAVING clause
          e13 = 'select path, max(response.duration) from logs.win:time_batch(10 seconds) where path.startsWith("/api/") group by path having max(response.duration) >= 100'
          x13 = 'select path, max(response$duration) from L111.win:time_batch(10 seconds) where path.startsWith("/api/") group by path having max(response$duration) >= 100'
          model = administrator.compileEPL(e13)
          mapping = {'logs' => 'L111'}
          expect(Norikra::Query.rewrite_query(model, mapping).toEPL).to eql(x13)
        end
      end
    end

    describe '.<=>' do
      it 'returns sort order by group,name' do
        q1 = Norikra::Query.new(:name => '211', :group => 'a1', :expression => 'x')
        q2 = Norikra::Query.new(:name => '111', :group => 'a1', :expression => 'x')
        q3 = Norikra::Query.new(:name => '011', :group => 'b1', :expression => 'x')
        q4 = Norikra::Query.new(:name => '011', :group => 'a1', :expression => 'x')
        q5 = Norikra::Query.new(:name => '999', :group => nil, :expression => 'x')
        q6 = Norikra::Query.new(:name => '899', :group => nil, :expression => 'x')

        expect([q1,q2,q3,q4,q5,q6].sort).to eql([q6,q5,q4,q2,q1,q3])
      end

      it 'must be stable for sort' do
        q1 = Norikra::Query.new(name: "hoge", group: nil, expression: "select hoge from pos")
        q2 = Norikra::Query.new(name: "test1", group: nil, expression: "select hoge,count(*)\r\nfrom pos\r\nwhere age >= 20\r\ngroup by hoge")
        q3 = Norikra::Query.new(name: "test2", group: "sweep1", expression: "select moge\r\nfrom pos.win:time_batch(5 sec)\r\nwhere x=1\r\n")
        expect([q1,q2,q3].sort).to eql([q1, q2, q3])
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
