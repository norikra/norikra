require_relative './spec_helper'

require 'norikra/fieldset'

require 'json'
require 'digest'

describe Norikra::FieldSet do
  describe 'can be initialized with both of Hash parameter and String' do
    it 'accepts String as type' do
      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long'})
      expect(set.fields['x'].type).to eql('string')
      expect(set.fields['y'].type).to eql('integer')
    end

    it 'sets optional specification nil as defaults' do
      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long'})
      expect(set.fields['x'].optional).to be_nil
      expect(set.fields['y'].optional).to be_nil
    end

    it 'accepts second argument as optional specification' do
      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long'}, false)
      expect(set.fields['x'].optional?).to be_false
      expect(set.fields['y'].optional?).to be_false

      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long'}, true)
      expect(set.fields['x'].optional?).to be_true
      expect(set.fields['y'].optional?).to be_true
    end

    it 'sets summary as comma-separated labeled field-type string with sorted field order' do
      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long'})
      expect(set.summary).to eql('x:string,y:integer')

      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long', 'a' => 'Boolean'})
      expect(set.summary).to eql('a:boolean,x:string,y:integer')
    end
  end

  context 'initialized with some fields' do
    set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long', 'a' => 'Boolean'})
    set2 = Norikra::FieldSet.new({'a' => 'string', 'b' => 'int', 'c' => 'float', 'd' => 'bool', 'e' => 'integer'})

    describe '#dup' do
      it 'make duplicated object with different internal instance' do
        x = set.dup
        expect(x.fields.object_id).not_to eql(set.fields.object_id)
        expect(x.fields).to eq(set.fields)
      end
    end

    describe '.leaves' do
      it 'raises ArgumentError for non-container values' do
        expect { Norikra::FieldSet.leaves('value') }.to raise_error(ArgumentError)
        expect { Norikra::FieldSet.leaves('') }.to raise_error(ArgumentError)
        expect { Norikra::FieldSet.leaves(1024) }.to raise_error(ArgumentError)
        expect { Norikra::FieldSet.leaves(nil) }.to raise_error(ArgumentError)
      end
      it 'returns blank array for empty container' do
        expect( Norikra::FieldSet.leaves({}) ).to eql([])
        expect( Norikra::FieldSet.leaves([]) ).to eql([])
      end

      it 'returns field access chains to all keys of 1-depth Hash container' do
        leaves = Norikra::FieldSet.leaves({'field1' => 1, 'field2' => 2})
        expect(leaves.size).to eql(2)
        expect(leaves).to eql([['field1', 1], ['field2', 2]])
      end

      it 'returns field access chains to all indexes of 1-depth Array container' do
        leaves = Norikra::FieldSet.leaves([1, 2, 3])
        expect(leaves.size).to eql(3)
        expect(leaves).to eql([[0, 1], [1, 2], [2, 3]])
      end

      it 'returns field access chains of 2-depth array' do
        leaves = Norikra::FieldSet.leaves([[0, 1, 2], 3, 4])
        expect(leaves.size).to eql(5)
        expect(leaves[0]).to eql([0, 0, 0])
        expect(leaves[1]).to eql([0, 1, 1])
        expect(leaves[2]).to eql([0, 2, 2])
        expect(leaves[3]).to eql([1, 3])
        expect(leaves[4]).to eql([2, 4])
      end

      it 'returns field access chains of deep containers' do
        leaves = Norikra::FieldSet.leaves({'f1' => [{'fz1' => 1, 'fz2' => {'fz3' => 2, 'fz4' => 3}}, 4], 'f2' => 5})
        expect(leaves.size).to eql(5)
        expect(leaves[0]).to eql(['f1', 0, 'fz1', 1])
        expect(leaves[1]).to eql(['f1', 0, 'fz2', 'fz3', 2])
        expect(leaves[2]).to eql(['f1', 0, 'fz2', 'fz4', 3])
        expect(leaves[3]).to eql(['f1', 1, 4])
        expect(leaves[4]).to eql(['f2', 5])
      end

      it 'does not return leaves with keys nil' do
        leaves = Norikra::FieldSet.leaves({'f1' => [{'fz1' => 1, nil => {'fz3' => 2, 'fz4' => 3}}, 4], nil => 5})
        expect(leaves.size).to eql(2)
        expect(leaves[0]).to eql(['f1', 0, 'fz1', 1])
        expect(leaves[1]).to eql(['f1', 1, 4])
      end

      it 'return leaves with values nil' do
        leaves = Norikra::FieldSet.leaves({'f1' => [{'fz1' => 1}, nil, 4], 'f2' => 5, 'f3' => nil})
        expect(leaves.size).to eql(5)
        expect(leaves[0]).to eql(['f1', 0, 'fz1', 1])
        expect(leaves[1]).to eql(['f1', 1, nil])
        expect(leaves[2]).to eql(['f1', 2, 4])
        expect(leaves[3]).to eql(['f2', 5])
        expect(leaves[4]).to eql(['f3', nil])
      end

      it 'does not return leaves with empty containers' do
        leaves = Norikra::FieldSet.leaves({'f1' => [{'fz1' => 1, 'fz2' => {}}, 4], 'f2' => 5, 'f3' => []})
        expect(leaves.size).to eql(3)
        expect(leaves[0]).to eql(['f1', 0, 'fz1', 1])
        expect(leaves[1]).to eql(['f1', 1, 4])
        expect(leaves[2]).to eql(['f2', 5])
      end
    end

    describe '.field_names_key' do
      it 'returns comma-separated sorted field names of argument hash' do
        expect(Norikra::FieldSet.field_names_key({'x1'=>1,'y3'=>2,'xx'=>3,'xx1'=>4,'a'=>5})).to eql('a,x1,xx,xx1,y3')
      end

      it 'returns comma-separated sorted field names of argument hash AND non-optional fields of 2nd argument fieldset instance' do
        expect(Norikra::FieldSet.field_names_key({'x1'=>1,'y3'=>2,'xx'=>3,'xx1'=>4}, set)).to eql('a,x,x1,xx,xx1,y,y3')
      end

      it 'returns only fields with defined previously in strict-mode' do
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'xx'=>3,'xx1'=>4}, set, true)).to eql('a,x,y')
      end

      it 'returns fields also in additional_fields in strict-mode and additional_fields' do
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'xx'=>3,'xx1'=>4,'xx2'=>5,'yy'=>6,'yy1'=>7}, set, true, ['xx2','yy1'])).to eql('a,x,xx2,y,yy1')
      end

      it 'returns result w/o chained field accesses not reserved (also in non-strict mode)' do
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'z'=>{'x1'=>1,'x2'=>2}}, set, true, [])).to eql('a,x,y')
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'z'=>{'x1'=>1,'x2'=>2}}, set, false, [])).to eql('a,x,y')
      end

      it 'returns result w/ reserved chained field accesses' do
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'z'=>{'x1'=>1,'x2'=>2}}, set, false, ['z.x2'])).to eql('a,x,y,z.x2')
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'z'=>{'x1'=>1,'x2'=>2}}, set, true, ['z.x1'])).to eql('a,x,y,z.x1')
      end

      it 'returns result w/ newly founded fields in non-strict mode, only for non-chained field accesses' do
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'z'=>{'x1'=>1,'x2'=>2},'p'=>true}, set, false, [])).to eql('a,p,x,y')
      end

      it 'returns result w/ regulared names for chained field accesses' do
        expect(Norikra::FieldSet.field_names_key({'x'=>1,'y'=>2,'z'=>['a','b','c']}, set, false, ['z.$0'])).to eql('a,x,y,z.$0')
      end
    end

    describe '#field_names_key' do
      it 'returns comma-separeted sorted field names' do
        expect(set.field_names_key).to eql('a,x,y')
      end
    end

    describe '#udpate_summary' do
      it 'changes summary with current @fields' do
        x = set.dup
        x.fields = set.fields.dup

        oldsummary = x.summary

        x.fields['x'] = Norikra::Field.new('x', 'int')

        expect(x.summary).to eql(oldsummary)

        x.update_summary

        expect(x.summary).not_to eql(oldsummary)
        expect(x.summary).to eql('a:boolean,x:integer,y:integer')
      end
    end

    describe '#update' do
      it 'changes field definition of this instance' do
        x = set.dup
        expect(x.fields['a'].type).to eql('boolean')
        expect(x.fields['x'].type).to eql('string')

        expect(x.fields['y'].type).to eql('integer')
        expect(x.fields['y'].optional).to be_nil

        x.update([Norikra::Field.new('y', 'int'), Norikra::Field.new('a','string')], false)

        expect(x.fields['y'].type).to eql('integer')
        expect(x.fields['y'].optional).to eql(false)

        expect(x.fields['x'].type).to eql('string')
        expect(x.fields['a'].type).to eql('string')
      end

      it 'adds field definition' do
        x = set.dup
        expect(x.fields.size).to eql(3)
        x.update([Norikra::Field.new('z', 'string')], true)
        expect(x.fields.size).to eql(4)
        expect(x.summary).to eql('a:boolean,x:string,y:integer,z:string')
      end
    end

    describe '#definition' do
      it 'returns hash instance of fieldname => esper type' do
        d = set.definition
        expect(d).to be_instance_of(Hash)
        expect(d.size).to eql(3)
        expect(d['a']).to eql('boolean')
        expect(d['x']).to eql('string')
        expect(d['y']).to eql('long')

        s = Norikra::FieldSet.new({'a' => 'string', 'b' => 'int', 'c' => 'float', 'd' => 'bool', 'e' => 'integer'})
        d = s.definition
        expect(d).to be_instance_of(Hash)
        expect(d.size).to eql(5)
        expect(d['a']).to eql('string')
        expect(d['b']).to eql('long')
        expect(d['c']).to eql('double')
        expect(d['d']).to eql('boolean')
        expect(d['e']).to eql('long')
      end
    end

    describe '#subset?' do
      it 'returns true when other instance has all fields of self' do
        other = Norikra::FieldSet.new({'a' => 'boolean', 'x' => 'string'})
        expect(set.subset?(other)).to be_false

        other.update([Norikra::Field.new('y', 'long')], false)
        expect(set.subset?(other)).to be_true

        other.update([Norikra::Field.new('z', 'double')], false)
        expect(set.subset?(other)).to be_true
      end
    end

    describe '#bind' do
      it 'sets event_type_name internally, and returns self' do
        x = set.dup

        expect(x.instance_eval{ @event_type_name }).to be_nil

        expect(x.bind('TargetExample', :query)).to eql(x)

        expect(x.instance_eval{ @event_type_name }).not_to be_nil
        expect(x.instance_eval{ @event_type_name }).to match(/q_[0-9a-f]{32}/) # MD5 hexdump
      end
    end

    describe '#rebind' do
      it 'returns duplicated object, but these event_type_name are same with false argument' do
        x = set.dup
        x.bind('TargetExample', :data)

        y = x.rebind(false)
        expect(y.summary).to eql(x.summary)
        expect(y.fields.values.map(&:to_hash)).to eql(x.fields.values.map(&:to_hash))
        expect(y.target).to eql(x.target)
        expect(y.level).to eql(x.level)
        expect(y.field_names_key).to eql(x.field_names_key)

        expect(y.event_type_name).to eql(x.event_type_name)
      end

      it 'returns duplicated object, and these event_type_name should be updated with true argument' do
        x = set.dup
        x.bind('TargetExample', :data)

        y = x.rebind(true)
        expect(y.summary).to eql(x.summary)
        expect(y.fields.values.map(&:to_hash)).to eql(x.fields.values.map(&:to_hash))
        expect(y.target).to eql(x.target)
        expect(y.level).to eql(x.level)
        expect(y.field_names_key).to eql(x.field_names_key)

        expect(y.event_type_name).not_to eql(x.event_type_name)
      end
    end

    describe '#event_type_name' do
      it 'returns duplicated string of @event_type_name' do
        x = set.dup
        x.bind('TargetExample', :query)
        internal = x.instance_eval{ @event_type_name }
        expect(x.event_type_name.object_id).not_to eql(internal.object_id)
        expect(x.event_type_name).to eql(internal)
      end
    end

    describe '#format' do
      it 'returns hash value with formatted fields as defined' do
        t = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'c' => 'boolean', 'd' => 'double'})

        d = t.format({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14'})
        expect(d['a']).to be_instance_of(String)
        expect(d['a']).to eql('hoge')
        expect(d['b']).to be_instance_of(Fixnum)
        expect(d['b']).to eql(2000)
        expect(d['c']).to be_instance_of(TrueClass)
        expect(d['c']).to eql(true)
        expect(d['d']).to be_instance_of(Float)
        expect(d['d']).to eql(3.14)
      end

      it 'returns data with keys encoded for chained field accesses' do
        t = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'e.$0' => 'string', 'f.foo.$$0' => 'string'})

        d = t.format({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14','e'=>['moris','tago'],'f'=>{'foo'=>{'0'=>'zero','1'=>'one'},'bar'=>{'0'=>'ZERO','1'=>'ONE'}}})
        expect(d.size).to eql(4)
        expect(d['a']).to be_instance_of(String)
        expect(d['a']).to eql('hoge')
        expect(d['b']).to be_instance_of(Fixnum)
        expect(d['b']).to eql(2000)
        expect(d['e$$0']).to be_instance_of(String)
        expect(d['e$$0']).to eql('moris')
        expect(d['f$foo$$$0']).to be_instance_of(String)
        expect(d['f$foo$$$0']).to eql('zero')
      end
    end
  end
end
