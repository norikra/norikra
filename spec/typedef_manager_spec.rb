require_relative './spec_helper'

require 'norikra/typedef_manager'

require 'norikra/typedef'

describe Norikra::TypedefManager do
  context 'when instanciated with a target without fields definition' do
    manager = Norikra::TypedefManager.new
    manager.add_target('sample', nil)

    describe '#lazy?' do
      it 'returns true' do
        expect(manager.lazy?('sample')).to be_truthy
      end
    end

    describe '#generate_base_fieldset' do
      it 'returns fieldsets specified as all fields required' do
        r = manager.generate_base_fieldset('sample', {'a'=>'foo','b'=>'bar','x'=>'yeeeees!'})
        expect(r).to be_instance_of(Norikra::FieldSet)

        expect(r.fields['a'].type).to eql('string')
        expect(r.fields['a'].optional?).to be_falsy
        expect(r.fields['b'].type).to eql('string')
        expect(r.fields['b'].optional?).to be_falsy
        expect(r.fields['x'].type).to eql('string')
        expect(r.fields['x'].optional?).to be_falsy
      end
    end

    describe '#activate' do
      it 'does not fail, and target will become non-lazy status' do
        r = manager.generate_base_fieldset('sample', {'a'=>'foo','b'=>'bar','x'=>'yeeeees!'})
        manager.activate('sample', r)
        expect(manager.lazy?('sample')).to be_falsy
      end
    end
  end

  context 'when instanciated with a target with fields definition' do
    manager = Norikra::TypedefManager.new
    manager.add_target('sample', {'a'=>'string','b'=>'string','c'=>'double'})
    manager.reserve('sample', 'z', 'boolean')
    manager.add_target('sample_next', {'a'=>'string','b'=>'string','c'=>'double','d'=>'double'})

    set_query_base = Norikra::FieldSet.new({'a'=>'string','b'=>'string','c'=>'double'})

    it 'three fields are defined as non-optional fields' do
      expect(manager.typedefs['sample'].fields['a'].type).to eql('string')
      expect(manager.typedefs['sample'].fields['a'].optional?).to be_falsy
      expect(manager.typedefs['sample'].fields['b'].type).to eql('string')
      expect(manager.typedefs['sample'].fields['b'].optional?).to be_falsy
      expect(manager.typedefs['sample'].fields['c'].type).to eql('float')
      expect(manager.typedefs['sample'].fields['c'].optional?).to be_falsy
    end

    describe '#lazy?' do
      it 'returns false' do
        expect(manager.lazy?('sample')).to be_falsy
      end
    end
    describe '#reserve' do
      it 'does not fail' do
        manager.reserve('sample', 'x', 'long')
        expect(manager.typedefs['sample'].fields['x'].type).to eql('integer')
        expect(manager.typedefs['sample'].fields['x'].optional?).to be_truthy
      end
    end

    describe '#ready?' do
      context 'with query with single target' do
        it 'returns boolean which matches target or not' do
          q1 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample.win:time(5 sec) where c > 1.0 and z')
          expect(manager.ready?(q1)).to be_truthy
          q2 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample.win:time(5 sec) where c > 1.0 and d > 2.0')
          expect(manager.ready?(q2)).to be_falsy
          q3 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample2.win:time(5 sec) where c > 1.0 and d > 2.0')
          expect(manager.ready?(q3)).to be_falsy
        end
      end

      context 'with query with multi targets, including unexisting target' do
        it 'returns false' do
          q = Norikra::Query.new(:name => 'test', :expression => 'select x.a,y.a from sample.win:time(5 sec) as x, sample2.win:time(5 sec) as y where x.c > 1.0 and y.d > 1.0')
          expect(manager.ready?(q)).to be_falsy
        end
      end

      context 'with query with multi targets, all of them are exisitng' do
        it 'returns true' do
          q = Norikra::Query.new(:name => 'test', :expression => 'select x.a,d from sample.win:time(5 sec) as x, sample_next.win:time(5 sec) as y where x.c > 1.0 and y.d > 1.0')
          expect(manager.ready?(q)).to be_truthy
        end
      end
    end

    describe '#register_waiting_fields' do
      context 'with query with single target' do
        it 'add no fields into waiting_fields about known fields only' do
          q1 = Norikra::Query.new(:name => 'test', :expression => 'select a,b from sample.win:time(5 sec) where c > 1.0')
          manager.register_waiting_fields(q1)
          q2 = Norikra::Query.new(:name => 'test', :expression => 'select a,b from sample.win:time(5 sec) where c > 1.0 and z')
          manager.register_waiting_fields(q2)
          q3 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample_next.win:time(5 sec) where c > 1.0 and d > 2.0')
          manager.register_waiting_fields(q3)

          expect(manager.typedefs['sample'].waiting_fields).to eql([])
          expect(manager.typedefs['sample_next'].waiting_fields).to eql([])
        end
      end

      context 'with query with single target with unknown fields' do
        it 'adds unknown fields into waiting_fields' do
          expect(manager.typedefs['sample'].waiting_fields).to eql([])
          expect(manager.typedefs['sample_next'].waiting_fields).to eql([])

          q1 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample.win:time(5 sec) where c > 1.0 and p')
          manager.register_waiting_fields(q1)
          q2 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample.win:time(5 sec) where c > 1.0 and p and q')
          manager.register_waiting_fields(q2)
          q3 = Norikra::Query.new(:name => 'test', :expression => 'select a,e from sample_next.win:time(5 sec) where c > 1.0 and d > 2.0')
          manager.register_waiting_fields(q3)

          expect(q1.fields('sample')).to eql(['a','c','p'])
          expect(q2.fields('sample')).to eql(['a','c','p','q'])
          expect(manager.typedefs['sample'].waiting_fields).to eql(['p', 'q'])
          expect(manager.typedefs['sample_next'].waiting_fields).to eql(['e'])
        end
      end
    end

    describe '#generate_fieldset_mapping' do
      it 'retuns collect mapping for fieldsets' do
        q1 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample.win:time(5 sec) where c > 1.0 and z')
        map1 = manager.generate_fieldset_mapping(q1)
        expect(map1.keys).to eql(['sample'])
        expect(map1.values.size).to eql(1)
        expect(map1.values.first).to be_a(Norikra::FieldSet)
        expect(map1.values.first.fields.size).to eql(4)
        expect(map1.values.first.fields.keys).to eql(['a','b','c','z']) # a,b,c is non-optional fields

        q2 = Norikra::Query.new(:name => 'test', :expression => 'select a from sample.win:time(5 sec) where c > 1.0')
        map2 = manager.generate_fieldset_mapping(q2)
        expect(map2.keys).to eql(['sample'])
        expect(map2.values.size).to eql(1)
        expect(map2.values.first).to be_a(Norikra::FieldSet)
        expect(map2.values.first.fields.size).to eql(3)
        expect(map2.values.first.fields.keys).to eql(['a','b','c']) # a,b,c is non-optional fields

        q3 = Norikra::Query.new(:name => 'test', :expression => 'select x.a, z from sample.win:time(5 sec) as x, sample_next.win:time(5 sec) as y where x.c > 1.0 and y.d > 1.0')
        map3 = manager.generate_fieldset_mapping(q3)
        expect(map3.keys).to eql(['sample', 'sample_next'])
        expect(map3['sample'].fields.keys).to eql(['a','b','c','z'])
        expect(map3['sample_next'].fields.keys).to eql(['a','b','c','d'])
      end
    end

    describe '#bind_fieldset and #unbind_fieldset' do
      it 'does not fail' do
        manager.bind_fieldset('sample', :query, set_query_base)
        expect(set_query_base.target).to eql('sample')
        expect(set_query_base.level).to eql(:query)
        expect(manager.typedefs['sample'].queryfieldsets.include?(set_query_base)).to be_truthy

        manager.unbind_fieldset('sample', :query, set_query_base)
        expect(manager.typedefs['sample'].queryfieldsets.include?(set_query_base)).to be_falsy
      end
    end

    describe '#base_fieldset' do
      it 'returns baseset of specified target' do
        expect(manager.base_fieldset('sample').object_id).to eql(manager.typedefs['sample'].baseset.object_id)
      end
    end

    describe '#refer' do
      it 'does not fail' do
        expect(manager.refer('sample', {'a'=>'foo','b'=>'bar','c'=>'0.03'})).to be_instance_of(Norikra::FieldSet)
      end
    end

    describe '#subsets' do
      it 'returns list of query fieldset (and base set), subset of specified fieldset, owned by manager for specified target' do
        base = {'a'=>'string','b'=>'string','c'=>'double'}
        set_d = Norikra::FieldSet.new(base.merge({'d'=>'int'}))
        manager.bind_fieldset('sample', :query, set_d)
        set_e = Norikra::FieldSet.new(base.merge({'e'=>'double'}))
        manager.bind_fieldset('sample', :query, set_e)
        set_f = Norikra::FieldSet.new(base.merge({'f'=>'boolean'}))
        manager.bind_fieldset('sample', :query, set_f)

        list = manager.subsets('sample', Norikra::FieldSet.new(base.merge({'d'=>'string','e'=>'string','g'=>'string'})))
        expect(list.size).to eql(3) # set_d, set_e, baseset
        expect(list.include?(set_d)).to be_truthy
        expect(list.include?(set_e)).to be_truthy
        expect(list.include?(set_f)).to be_falsy
      end
    end

    describe '#supersets' do
      it 'returns list of data fieldset, superset of specified fieldset, owned by manager for specified target' do
        base = {'a'=>'string','b'=>'string','c'=>'double'}
        set_x = Norikra::FieldSet.new(base.merge({'one'=>'int','two'=>'string','three'=>'double'}))
        manager.bind_fieldset('sample', :data, set_x)
        set_y = Norikra::FieldSet.new(base.merge({'one'=>'int','two'=>'string'}))
        manager.bind_fieldset('sample', :data, set_y)
        set_z = Norikra::FieldSet.new(base.merge({'one'=>'int','two'=>'string','three'=>'double','four'=>'boolean'}))
        manager.bind_fieldset('sample', :data, set_z)

        list = manager.supersets('sample', Norikra::FieldSet.new({'one'=>'int','three'=>'double'}))
        expect(list.size).to eql(2) # set_x, set_z
        expect(list.include?(set_x)).to be_truthy
        expect(list.include?(set_y)).to be_falsy
        expect(list.include?(set_z)).to be_truthy
      end
    end

    describe '#generate_query_fieldset' do
      it 'returns fieldset instance with all required(non-optional) fields of target, and fields of query requires' do
        r = manager.generate_query_fieldset('sample', ['a', 'b', 'f'], [], 'qname1', nil)
        expect(r.fields.size).to eql(4) # a,b,c,f
        expect(r.summary).to eql('a:string,b:string,c:float,f:boolean')
      end

      it 'returns fieldset instance with nullable information if specified' do
        r = manager.generate_query_fieldset('sample', ['a', 'b', 'f'], ['b', 'f'], 'qname1', nil)
        expect(r.fields.size).to eql(4) # a,b,c,f
        expect(r.summary).to eql('a:string,b:string:nullable,c:float,f:boolean:nullable')
      end
    end

    describe '#dump_target' do
      it 'returns target typedef dump' do
        m = Norikra::TypedefManager.new
        m.add_target('sample', {'a'=>'string','b'=>'string','c'=>'double'})
        m.reserve('sample', 'z', 'boolean')
        m.add_target('sample_next', {'a'=>'string','b'=>'string','c'=>'double','d'=>'double'})

        r = m.dump_target('sample')
        expect(r).to eql({
            a: {name: 'a', type: 'string', optional: false, nullable: false},
            b: {name: 'b', type: 'string', optional: false, nullable: false},
            c: {name: 'c', type: 'float', optional: false, nullable: false},
            z: {name: 'z', type: 'boolean', optional: true, nullable: false},
          })

        r = m.dump_target('sample_next')
        expect(r).to eql({
            a: {name: 'a', type: 'string', optional: false, nullable: false},
            b: {name: 'b', type: 'string', optional: false, nullable: false},
            c: {name: 'c', type: 'float', optional: false, nullable: false},
            d: {name: 'd', type: 'float', optional: false, nullable: false},
          })
      end
    end
  end
end
