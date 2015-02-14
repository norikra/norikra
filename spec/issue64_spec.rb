require_relative './spec_helper'

require 'norikra/engine'
require 'norikra/output_pool'
require 'norikra/typedef_manager'

include Norikra::SpecHelper

describe "Query" do
  describe "#rewrite_query" do
    it "keep outer alias not replaced" do
      expression = 'select a, (select sum(b) from mytarget.win:length(3) as alias2 where alias1.c=alias2.c) as x from mytarget as alias1'
      expected   = 'select a, (select sum(b) from M1.win:length(3) as alias2 where alias1.c=alias2.c) as x from M1 as alias1'
      with_engine do
        statement_model = administrator.compileEPL(expression)
        mapping = {"mytarget"=>"M1"}
        Norikra::Query.rewrite_query(statement_model, mapping)
        expect(statement_model.toEPL).to eql(expected)
      end
    end
  end
  describe "#rewrite_event_field_name" do
    it "keep outer alias not replaced" do
      expression = 'select a, (select sum(b) from mytarget.win:length(3) as alias2 where alias1.c=alias2.c) as x from mytarget as alias1'
      expected   = 'select a, (select sum(b) from mytarget.win:length(3) as alias2 where alias1.c=alias2.c) as x from mytarget as alias1'
      with_engine do
        statement_model = administrator.compileEPL(expression)
        mapping = {}
        Norikra::Query.rewrite_event_field_name(statement_model, mapping)
        expect(statement_model.toEPL).to eql(expected)
      end
    end
  end
end

describe "Engine(running)" do
  before :each do
    @typedef_manager = Norikra::TypedefManager.new
    @output_pool = Norikra::OutputPool.new
    @engine = Norikra::Engine.new(@output_pool, @typedef_manager, {})
    @engine.start
  end
  after :each do
    @engine.stop
  end

  context "subquery using outer target alias" do
    it 'should not raise' do
      begin
        target_name = "mytarget"
        query_name  = "q1"
        query_group = "g1"
        expression  = "select a,(select sum(b) from mytarget.win:length(3) as alias2 where alias1.c=alias2.c) as x from mytarget as alias1"
        query = Norikra::Query.new(name: query_name, group: query_group, expression: expression)
        @engine.register(query)

        events = [
          {"a"=>1, "b"=>2, "c"=>3},
          {"a"=>2, "b"=>2, "c"=>4},
          {"a"=>3, "b"=>2, "c"=>3},
          {"a"=>4, "b"=>2, "c"=>4},
          {"a"=>5, "b"=>2, "c"=>5},
          {"a"=>6, "b"=>2, "c"=>5},
          {"a"=>7, "b"=>2, "c"=>5},
          {"a"=>8, "b"=>2, "c"=>5}
        ]
        events.each do |e|
          @engine.send("mytarget", [e])
        end

        output = @engine.output_pool.pop(query_name)

        expect(output).not_to be_nil
        expect(output.size).to eql 8
        expect(output[0][1]).to eql({"a"=>1, "x"=>2})
        expect(output[1][1]).to eql({"a"=>2, "x"=>2})
        expect(output[2][1]).to eql({"a"=>3, "x"=>4})
        expect(output[3][1]).to eql({"a"=>4, "x"=>4})
        expect(output[4][1]).to eql({"a"=>5, "x"=>2})
        expect(output[5][1]).to eql({"a"=>6, "x"=>4})
        expect(output[6][1]).to eql({"a"=>7, "x"=>6})
        expect(output[7][1]).to eql({"a"=>8, "x"=>6})
      rescue Object => e
        puts $dummylogger.output
        raise e
      end
    end
  end

  context "simple select" do
    it 'returns all events' do
      target_name = "mytarget"
      query_name  = "q1"
      query_group = "g1"
      expression  = "select a,b,c from #{target_name}"
      query = Norikra::Query.new(name: query_name, group: query_group, expression: expression)
      @engine.register(query)

      e1 = {"a"=>1, "b"=>2, "c"=>3}
      e2 = {"a"=>6, "b"=>5, "c"=>4}
      @engine.send(target_name, [e1]);
      @engine.send(target_name, [e2]);

      output = @engine.output_pool.pop(query_name)

      expect(output).not_to be_nil
      expect(output.size).to eql 2
      expect(output[0][1]).to eql e1
      expect(output[1][1]).to eql e2
    end

    it 'returns sum,avg' do
      target_name = "mytarget"
      query_name  = "q1"
      query_group = "g1"
      expression  = "select sum(a),avg(b),c from #{target_name}"
      query = Norikra::Query.new(name: query_name, group: query_group, expression: expression)
      @engine.register(query)

      e1 = {"a"=>1, "b"=>2, "c"=>3}
      e2 = {"a"=>6, "b"=>5, "c"=>4}
      @engine.send(target_name, [e1]);
      @engine.send(target_name, [e2]);

      output = @engine.output_pool.pop(query_name)

      expect(output).not_to be_nil
      expect(output.size).to eql 2
      expect(output[0][1]).to eql({"sum(a)"=>1,"avg(b)"=>2.0,"c"=>3})
      expect(output[1][1]).to eql({"sum(a)"=>7,"avg(b)"=>3.5,"c"=>4})
    end
  end
end
