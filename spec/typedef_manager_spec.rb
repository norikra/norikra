require_relative './spec_helper'

require 'norikra/typedef_manager'

require 'norikra/typedef'

describe Norikra::TypedefManager do
  context 'when instanciated with a target without fields definition' do
    manager = Norikra::TypedefManager.new
    manager.add_target('sample', nil)

    describe '#lazy?' do
      it 'returns true' do
        expect(manager.lazy?('sample')).to be_true
      end
    end

    describe '#generate_base_fieldset' do
      it 'returns fieldsets specified as all fields required' do
        r = manager.generate_base_fieldset('sample', {'a'=>'foo','b'=>'bar','x'=>'yeeeees!'})
        expect(r).to be_instance_of(Norikra::FieldSet)

        expect(r.fields['a'].type).to eql('string')
        expect(r.fields['a'].optional?).to be_false
        expect(r.fields['b'].type).to eql('string')
        expect(r.fields['b'].optional?).to be_false
        expect(r.fields['x'].type).to eql('string')
        expect(r.fields['x'].optional?).to be_false
      end
    end

    describe '#activate' do
      it 'does not fail, and target will become non-lazy status' do
        r = manager.generate_base_fieldset('sample', {'a'=>'foo','b'=>'bar','x'=>'yeeeees!'})
        manager.activate('sample', r)
        expect(manager.lazy?('sample')).to be_false
      end
    end
  end

  context 'when instanciated with a target with fields definition' do
    manager = Norikra::TypedefManager.new
    manager.add_target('sample', {'a'=>'string','b'=>'string','c'=>'double'})

    set_query_base = Norikra::FieldSet.new({'a'=>'string','b'=>'string','c'=>'double'})

    it 'three fields are defined as non-optional fields' do
      expect(manager.typedefs['sample'].fields['a'].type).to eql('string')
      expect(manager.typedefs['sample'].fields['a'].optional?).to be_false
      expect(manager.typedefs['sample'].fields['b'].type).to eql('string')
      expect(manager.typedefs['sample'].fields['b'].optional?).to be_false
      expect(manager.typedefs['sample'].fields['c'].type).to eql('double')
      expect(manager.typedefs['sample'].fields['c'].optional?).to be_false
    end

    describe '#lazy?' do
      it 'returns false' do
        expect(manager.lazy?('sample')).to be_false
      end
    end
    describe '#reserve' do
      it 'does not fail' do
        manager.reserve('sample', 'x', 'long')
        expect(manager.typedefs['sample'].fields['x'].type).to eql('long')
        expect(manager.typedefs['sample'].fields['x'].optional?).to be_true
      end
    end
    describe '#fields_defined?' do
      it 'does not fail' do
        expect(manager.fields_defined?('sample', ['a','b','x'])).to be_true
        expect(manager.fields_defined?('sample', ['a','b','z'])).to be_false
      end
    end
    describe '#bind_fieldset' do
      it 'does not fail' do
        manager.bind_fieldset('sample', :query, set_query_base)
        expect(set_query_base.target).to eql('sample')
        expect(set_query_base.level).to eql(:query)
        expect(manager.typedefs['sample'].queryfieldsets.include?(set_query_base)).to be_true
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

    describe '#format' do
      it 'does not fail' do
        expect(manager.format('sample', {'a'=>'foo','b'=>'bar','c'=>'0.03'})).to be_instance_of(Hash)
      end
    end

    describe '#subsets' do
      it 'returns list of query fieldset (and base set), subset of specified fieldset, owned by manager for specified target' do
        base = {'a'=>'string','b'=>'string','c'=>'double'}
        set_d = Norikra::FieldSet.new(base.merge({'d'=>'integer'}))
        manager.bind_fieldset('sample', :query, set_d)
        set_e = Norikra::FieldSet.new(base.merge({'e'=>'double'}))
        manager.bind_fieldset('sample', :query, set_e)
        set_f = Norikra::FieldSet.new(base.merge({'f'=>'boolean'}))
        manager.bind_fieldset('sample', :query, set_f)

        list = manager.subsets('sample', Norikra::FieldSet.new(base.merge({'d'=>'string','e'=>'string','g'=>'string'})))
        expect(list.size).to eql(4) # set_query_base, set_d, set_e, baseset
        expect(list.include?(set_query_base)).to be_true
        expect(list.include?(set_d)).to be_true
        expect(list.include?(set_e)).to be_true
        expect(list.include?(set_f)).to be_false
      end
    end

    describe '#generate_query_fieldset' do
      it 'returns fieldset instance with all required(non-optional) fields of target, and fields of query requires' do
        r = manager.generate_query_fieldset('sample', ['a', 'b','f'])
        expect(r.fields.size).to eql(4) # a,b,c,f
        expect(r.summary).to eql('a:string,b:string,c:double,f:boolean')
      end
    end
  end
end
