require_relative './spec_helper'

require 'norikra/typedef'

require 'json'
require 'digest'

describe Norikra::FieldSet do
  describe '.simple_guess' do
    it 'can guess field definitions with class of values' do
      t = Norikra::FieldSet.simple_guess({'key1' => true, 'key2' => false, 'key3' => 10, 'key4' => 3.1415, 'key5' => 'foobar'})
      r = t.definition
      expect(r['key1']).to eql('boolean')
      expect(r['key2']).to eql('boolean')
      expect(r['key3']).to eql('long')
      expect(r['key4']).to eql('double')
      expect(r['key5']).to eql('string')
    end

    it 'does not guess with content of string values' do
      t = Norikra::FieldSet.simple_guess({'key1' => 'TRUE', 'key2' => 'false', 'key3' => "10", 'key4' => '3.1415', 'key5' => {:a => 1}})
      r = t.definition
      expect(r['key1']).to eql('string')
      expect(r['key2']).to eql('string')
      expect(r['key3']).to eql('string')
      expect(r['key4']).to eql('string')
      expect(r['key5']).to eql('string')
    end
  end

  describe 'can be initialized with both of Hash parameter and String' do
    it 'accepts String as type' do
      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long'})
      expect(set.fields['x'].type).to eql('string')
      expect(set.fields['y'].type).to eql('long')
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
      expect(set.summary).to eql('x:string,y:long')

      set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long', 'a' => 'Boolean'})
      expect(set.summary).to eql('a:boolean,x:string,y:long')
    end
  end

  context 'initialized with some fields' do
    set = Norikra::FieldSet.new({'x' => 'string', 'y' => 'long', 'a' => 'Boolean'})

    describe '#dup' do
      it 'make duplicated object with different internal instance' do
        x = set.dup
        expect(x.fields.object_id).not_to eql(set.fields.object_id)
        expect(x.fields).to eq(set.fields)
      end
    end

    describe '.field_names_key' do
      it 'returns comma-separated sorted field names of argument hash' do
        expect(Norikra::FieldSet.field_names_key({'x1'=>1,'y3'=>2,'xx'=>3,'xx1'=>4,'a'=>5})).to eql('a,x1,xx,xx1,y3')
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
        expect(x.summary).to eql('a:boolean,x:int,y:long')
      end
    end

    describe '#update' do
      it 'changes field definition of this instance' do
        x = set.dup
        expect(x.fields['a'].type).to eql('boolean')
        expect(x.fields['x'].type).to eql('string')

        expect(x.fields['y'].type).to eql('long')
        expect(x.fields['y'].optional).to be_nil

        x.update([Norikra::Field.new('y', 'int'), Norikra::Field.new('a','string')], false)

        expect(x.fields['y'].type).to eql('int')
        expect(x.fields['y'].optional).to eql(false)

        expect(x.fields['x'].type).to eql('string')
        expect(x.fields['a'].type).to eql('string')
      end

      it 'adds field definition' do
        x = set.dup
        expect(x.fields.size).to eql(3)
        x.update([Norikra::Field.new('z', 'string')], true)
        expect(x.fields.size).to eql(4)
        expect(x.summary).to eql('a:boolean,x:string,y:long,z:string')
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
  end
end
