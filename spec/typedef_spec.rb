require_relative './spec_helper'

require 'norikra/typedef'
# require 'norikra/error'

require 'json'
require 'digest'

describe Norikra::Typedef do
  context 'instanciated as lazy typedef' do
    it 'has no fields' do
      t = Norikra::Typedef.new
      expect(t.fields.size).to eql(0)
      expect(t.baseset).to be_nil
    end

    it 'has no query/data fieldsets' do
      t = Norikra::Typedef.new
      expect(t.queryfieldsets.size).to eql(0)
      expect(t.datafieldsets.size).to eql(0)
    end

    describe '#lazy?' do
      it 'returns true' do
        t = Norikra::Typedef.new
        expect(t.lazy?).to be_true
      end
    end

    describe '#reserve' do
      it 'add field definition without any baseset' do
        t = Norikra::Typedef.new

        t.reserve('k', 'string')
        expect(t.fields['k'].type).to eql('string')
        expect(t.fields['k'].optional?).to be_true

        t.reserve('l', 'long', false)
        expect(t.fields['l'].type).to eql('long')
        expect(t.fields['l'].optional?).to be_false
      end
    end

    describe '#activate' do
      context 'without any fields reserved' do
        it 'stores all fields in specified fieldset' do
          t = Norikra::Typedef.new
          set = Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double'})
          set.target = 'testing'
          set.level = :base
          t.activate(set)
          expect(t.fields.size).to eql(3)
          expect(t.fields['a'].optional?).to be_false
          expect(t.fields.object_id).not_to eql(set.fields.object_id)
          expect(t.baseset.object_id).not_to eql(set.object_id)
        end
      end
    end
  end

  context 'instanciated as non-lazy typedef' do
    it 'has no query/data fieldsets' do
      t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
      expect(t.queryfieldsets.size).to eql(0)
      expect(t.datafieldsets.size).to eql(0)
    end

    it 'has all fields as required' do
      t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

      expect(t.fields['a'].type).to eql('string')
      expect(t.fields['a'].optional?).to be_false

      expect(t.fields['b'].type).to eql('long')
      expect(t.fields['b'].optional?).to be_false
    end

    describe '#lazy?' do
      it 'returns false' do
        t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
        expect(t.lazy?).to be_false
      end
    end

    describe '#field_defined?' do
      it 'returns boolean to indicate all fields specified exists or not' do
        t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
        expect(t.field_defined?(['a','b'])).to be_true
        expect(t.field_defined?(['a'])).to be_true
        expect(t.field_defined?(['b'])).to be_true
        expect(t.field_defined?([])).to be_true
        expect(t.field_defined?(['a','b','c'])).to be_false
        expect(t.field_defined?(['a','c'])).to be_false
        expect(t.field_defined?(['c'])).to be_false
      end
    end

    describe '#reserve' do
      it 'adds field definitions as required or optional' do
        t = Norikra::Typedef.new({'a' => 'string'})

        expect(t.fields.size).to eql(1)

        t.reserve('b', 'boolean', false)
        expect(t.fields.size).to eql(2)
        expect(t.fields['b'].type).to eql('boolean')
        expect(t.fields['b'].optional?).to be_false

        t.reserve('c', 'double', true)
        expect(t.fields.size).to eql(3)
        expect(t.fields['c'].type).to eql('double')
        expect(t.fields['c'].optional?).to be_true
      end
    end

    describe '#consistent?' do
      context 'without any additional reserved fields' do
        it 'checks all fields of specified fieldset are super-set of baseset or not' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long'})
          expect(t.consistent?(set)).to be_true

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'c' => 'double'})
          expect(t.consistent?(set)).to be_true

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'int'})
          expect(t.consistent?(set)).to be_false

          set = Norikra::FieldSet.new({'a' => 'string'})
          expect(t.consistent?(set)).to be_false
        end
      end

      context 'with some additional reserved fields' do
        it 'checks all fields of specified fieldset with baseset and additional reserved fields' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
          t.reserve('c', 'double', false) # required
          t.reserve('d', 'boolean', true) # optional

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long'})
          expect(t.consistent?(set)).to be_false

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'c' => 'double'})
          expect(t.consistent?(set)).to be_true

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'c' => 'double', 'd' => 'boolean'})
          expect(t.consistent?(set)).to be_true

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'c' => 'double', 'd' => 'string'})
          expect(t.consistent?(set)).to be_false

          set = Norikra::FieldSet.new({'a' => 'string', 'b' => 'long', 'c' => 'double', 'd' => 'boolean', 'e' => 'string'})
          expect(t.consistent?(set)).to be_true
        end
      end
    end

    describe '#push' do
      it 'does not accepts fieldset which conflicts pre-defined fields' do
        t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
        expect { t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'int'})) }.to raise_error(Norikra::ArgumentError)
        expect { t.push(:data, Norikra::FieldSet.new({'a'=>'string'})) }.to raise_error(Norikra::ArgumentError)
      end

      it 'accepts fieldsets which is consistent with self' do
        t = Norikra::Typedef.new({'a'=>'string','b'=>'long'})
        expect(t.fields.size).to eql(2)

        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))

        expect(t.fields.size).to eql(2)

        set_a = Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double'})
        t.push(:data, set_a)
        expect(t.fields.size).to eql(3)
        expect(t.fields['c'].type).to eql('double')
        expect(t.fields['c'].optional?).to be_true

        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long','d'=>'string'}))
        expect(t.fields.size).to eql(4)
        expect(t.fields['d'].type).to eql('string')
        expect(t.fields['d'].optional?).to be_true
      end
    end

    describe '#pop' do
      it 'does not accepts base/data fieldsets' do
        t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
        expect { t.pop(:base, Norikra::FieldSet.new({'a'=>'string','b'=>'int'})) }.to raise_error(RuntimeError)
        expect { t.pop(:data, Norikra::FieldSet.new({'a'=>'string'})) }.to raise_error(RuntimeError)
      end

      it 'removes specified query fieldset from queryfieldsets' do
        t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
        set1 = Norikra::FieldSet.new({'a'=>'string','b' => 'long','c'=>'int'})
        set2 = Norikra::FieldSet.new({'a'=>'string','b' => 'long'})
        t.push(:query, set1)
        t.push(:query, set2)

        expect(t.queryfieldsets.size).to eql(2)

        t.pop(:query, set1)
        expect(t.queryfieldsets.size).to eql(1)
        t.pop(:query, set2)
        expect(t.queryfieldsets.size).to eql(0)
      end
    end

    describe '#replace' do
      it 'raises error for different field name sets' do
        t = Norikra::Typedef.new({'a'=>'string'})
        set1 = Norikra::FieldSet.new({'a'=>'string','b'=>'int'})
        set2 = Norikra::FieldSet.new({'a'=>'string','c'=>'int'})
        t.push(:data, set1)
        expect { t.replace(:data, set1, set2) }.to raise_error(Norikra::ArgumentError)
      end

      it 'replaces typedef internal fieldset object for specified field_names_key' do
        t = Norikra::Typedef.new({'a'=>'string'})
        set1 = Norikra::FieldSet.new({'a'=>'string','b'=>'int'}).bind('x', :data)
        t.push(:data, set1)
        expect(t.instance_eval{ @set_map['a,b'].event_type_name }).to eql(set1.event_type_name)
        expect(t.instance_eval{ @datafieldsets.size }).to eql(1)

        set2 = set1.rebind(true) # replacing needs updated event_type_name
        t.replace(:data, set1, set2)
        expect(t.instance_eval{ @datafieldsets.size }).to eql(1)
        expect(t.instance_eval{ @set_map['a,b'].event_type_name }).not_to eql(set1.event_type_name)
        expect(t.instance_eval{ @set_map['a,b'].event_type_name }).to eql(set2.event_type_name)
      end
    end

    describe '#refer' do
      context 'for event defined by data-fieldset already known' do
        it 'returns fieldset that already known itself' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

          set1 = Norikra::FieldSet.new({'a'=>'string','b'=>'long'})
          t.push(:data, set1)

          r = t.refer({'a'=>'foobar','b'=>200000000})
          expect(r).to be_instance_of(Norikra::FieldSet)
          expect(r.object_id).to eql(set1.object_id)
        end
      end

      context 'for event with known fields only' do
        it 'returns fieldset that is overwritten with known field definitions' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
          t.reserve('c','boolean',true)
          t.reserve('d','double',true)

          r = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14'})
          expect(t.datafieldsets.include?(r)).to be_false

          expect(r.fields['a'].type).to eql('string')
          expect(r.fields['b'].type).to eql('long')
          expect(r.fields['c'].type).to eql('boolean')
          expect(r.fields['d'].type).to eql('double')
          expect(r.summary).to eql('a:string,b:long,c:boolean,d:double')
        end
      end

      context 'for event with some unknown fields' do
        it 'returns fieldset that contains fields as string for unknowns' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

          r = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14'})
          expect(t.datafieldsets.include?(r)).to be_false

          expect(r.fields['a'].type).to eql('string')
          expect(r.fields['b'].type).to eql('long')
          expect(r.fields['c'].type).to eql('string')
          expect(r.fields['d'].type).to eql('string')
          expect(r.summary).to eql('a:string,b:long,c:string,d:string')
        end
      end
    end

    describe '#format' do
      it 'returns hash value with formatted fields as defined' do
        t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
        t.reserve('c','boolean',true)
        t.reserve('d','double',true)

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
    end

    describe '#dump' do
      it 'returns hash instance to show fields and its types/optionals' do
        t = Norikra::Typedef.new({'a'=>'string','b'=>'long'})
        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double'}))
        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long','d'=>'string'}))
        fields = t.fields

        r = t.dump
        expect(r.keys.sort).to eql([:a, :b, :c, :d])
        expect(r[:a]).to eql({name: 'a', type: 'string', optional: false})
        expect(r[:b]).to eql({name: 'b', type: 'long', optional: false})
        expect(r[:c]).to eql({name: 'c', type: 'double', optional: true})
        expect(r[:d]).to eql({name: 'd', type: 'string', optional: true})

        t2 = Norikra::Typedef.new(r)
        expect(t2.fields.keys.sort).to eql(fields.keys.sort)
        expect(t2.fields.values.map(&:to_hash)).to eql(fields.values.map(&:to_hash))
      end
    end
  end
end
