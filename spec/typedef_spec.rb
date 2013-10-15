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

      it 'remove waiting field' do
        t = Norikra::Typedef.new
        t.waiting_fields = ['c', 'l', 'k', 'z']

        t.reserve('k', 'string')
        t.reserve('l', 'long', false)

        expect(t.waiting_fields).to eql(['c','z'])
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

      context 'with waiting fields' do
        it 'remove fields in waitings' do
          t = Norikra::Typedef.new
          t.waiting_fields = ['a', 'c']

          set = Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double'})
          set.target = 'testing'
          set.level = :base
          t.activate(set)

          expect(t.waiting_fields).to eql([])
        end

        it 'does not remove fields in waitings without definition in base fieldset' do
          t = Norikra::Typedef.new
          t.waiting_fields = ['a', 'c', 'x', 'y', 'z']

          set = Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double'})
          set.target = 'testing'
          set.level = :base
          t.activate(set)

          expect(t.waiting_fields).to eql(['x', 'y', 'z'])
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

    it 'has container fields with chained access fields' do
      t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long', 'c.0' => 'boolean'})
      expect(t.fields.size).to eql(3)
      expect(t.container_fields.size).to eql(1)
      expect(t.container_fields['c'].name).to eql('c')
      expect(t.container_fields['c'].type).to eql('array')
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

      it 'deletes waiting fields' do
        t = Norikra::Typedef.new({'a'=>'string','b'=>'long'})
        t.waiting_fields = ['c', 'd', 'e']

        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))

        expect(t.waiting_fields.size).to eql(3)

        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double'}))
        expect(t.waiting_fields).to eql(['d','e'])

        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long','d'=>'string'}))
        expect(t.waiting_fields).to eql(['e'])
      end

      it 'deletes waiting chained access fields' do
        t = Norikra::Typedef.new({'a'=>'string','b'=>'long'})
        t.waiting_fields = ['c', 'd', 'e', 'f.0', 'f.1', 'g.fieldx']

        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long'}))

        expect(t.waiting_fields.size).to eql(6)

        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double','g.fieldy'=>'long','g.fieldz'=>'string'}))
        expect(t.waiting_fields).to eql(['d','e','f.0','f.1','g.fieldx'])

        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long','d'=>'string','f.0'=>'long','f.1'=>'long','g.fieldx'=>'string'}))
        expect(t.waiting_fields).to eql(['e'])
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

    describe '#simple_guess' do
      it 'can guess field definitions with class of values' do
        typedef = Norikra::Typedef.new({'key1' => 'boolean'})
        t = typedef.simple_guess({'key1' => true, 'key2' => false, 'key3' => 10, 'key4' => 3.1415, 'key5' => 'foobar'})
        r = t.definition
        expect(r['key1']).to eql('boolean')
        expect(r['key2']).to eql('boolean')
        expect(r['key3']).to eql('long')
        expect(r['key4']).to eql('double')
        expect(r['key5']).to eql('string')
        expect(r.keys.size).to eql(5)
      end

      it 'does not guess with content of string values, nor containers' do
        typedef = Norikra::Typedef.new({})
        t = typedef.simple_guess({'key1' => 'TRUE', 'key2' => 'false', 'key3' => "10", 'key4' => '3.1415', 'key5' => {:a => 1}})
        r = t.definition
        expect(r.size).to eql(4)
        expect(r['key1']).to eql('string')
        expect(r['key2']).to eql('string')
        expect(r['key3']).to eql('string')
        expect(r['key4']).to eql('string')
      end

      it 'can guess about fields already known with strict mode' do
        typedef = Norikra::Typedef.new({'key1' => 'boolean', 'key2' => 'boolean', 'key3' => 'long'})
        t = typedef.simple_guess({'key1' => true, 'key2' => false, 'key3' => 10, 'key4' => 3.1415, 'key5' => 'foobar'}, true, true)
        r = t.definition
        expect(r['key1']).to eql('boolean')
        expect(r['key2']).to eql('boolean')
        expect(r['key3']).to eql('long')
        expect(r['key4']).to be_nil
        expect(r['key5']).to be_nil
        expect(r.keys.size).to eql(3)
      end

      it 'can guess about fields already known or waiting fields with strict mode' do
        typedef = Norikra::Typedef.new({'key1' => 'boolean', 'key2' => 'boolean', 'key3' => 'long'})
        typedef.waiting_fields = ['key5']

        t = typedef.simple_guess({'key1' => true, 'key2' => false, 'key3' => 10, 'key4' => 3.1415, 'key5' => 'foobar'}, true, true)
        r = t.definition
        expect(r['key1']).to eql('boolean')
        expect(r['key2']).to eql('boolean')
        expect(r['key3']).to eql('long')
        expect(r['key4']).to be_nil
        expect(r['key5']).to eql('string')
        expect(r.keys.size).to eql(4)
      end

      it 'can guess about container chain access fields which pre-defined or be waiting' do
        typedef = Norikra::Typedef.new({'key1' => 'boolean', 'key2' => 'long', 'key3.0.key4' => 'string'})
        typedef.waiting_fields = ['key4.f1', 'key4.f2.0', 'key5']

        t = typedef.simple_guess({
            'key1' => true,
            'key2' => 10,
            'key3' => [{'k2' => 1, 'k3' => 'sssss', 'key4' => 'baz'}],
            'key4' => {'f1' => 'xxx', 'f2' => [30, true]},
            'key5' => 'foobar'
          }, true, true)
        r = t.definition
        expect(r.size).to eql(6)
        expect(r['key1']).to eql('boolean')
        expect(r['key2']).to eql('long')
        expect(r['key3$$0$key4']).to eql('string')
        expect(r['key4$f1']).to eql('string')
        expect(r['key4$f2$$0']).to eql('long')
        expect(r['key5']).to eql('string')
      end
    end

    describe '#refer' do
      context 'in non-strict mode' do
        it 'returns fieldset that already known itself for event defined by data-fieldset already known' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

          set1 = Norikra::FieldSet.new({'a'=>'string','b'=>'long'})
          t.push(:data, set1)

          r = t.refer({'a'=>'foobar','b'=>200000000})
          expect(r).to be_instance_of(Norikra::FieldSet)
          expect(r.object_id).to eql(set1.object_id)
        end

        it 'returns fieldset that is overwritten with known field definitions for event with known fields only' do
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

        it 'returns fieldset that contains fields as string for unknowns for event with some unknown fields' do
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

      context 'in strict mode' do
        it 'returns fieldset that already known itself for event defined by data-fieldset already known' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

          set1 = Norikra::FieldSet.new({'a'=>'string','b'=>'long'})
          t.push(:data, set1)

          r = t.refer({'a'=>'foobar','b'=>200000000}, true)
          expect(r).to be_instance_of(Norikra::FieldSet)
          expect(r.object_id).to eql(set1.object_id)
        end

        it 'returns fieldset that is overwritten with known field definitions for event with known fields only' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
          t.reserve('c','boolean',true)
          t.reserve('d','double',true)

          r = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14'}, true)
          expect(t.datafieldsets.include?(r)).to be_false

          expect(r.fields['a'].type).to eql('string')
          expect(r.fields['b'].type).to eql('long')
          expect(r.fields['c'].type).to eql('boolean')
          expect(r.fields['d'].type).to eql('double')
          expect(r.summary).to eql('a:string,b:long,c:boolean,d:double')
        end

        it 'returns fieldset that contains fields already known only for event with some unknown fields' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})

          r1 = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14'}, true)
          expect(t.datafieldsets.include?(r1)).to be_false

          expect(r1.fields['a'].type).to eql('string')
          expect(r1.fields['b'].type).to eql('long')
          expect(r1.summary).to eql('a:string,b:long')

          r2 = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14', 'e' => 'yeeeeeees!'}, true)
          expect(t.datafieldsets.include?(r2)).to be_false

          expect(r2.fields['a'].type).to eql('string')
          expect(r2.fields['b'].type).to eql('long')
          expect(r2.summary).to eql('a:string,b:long')
        end

        it 'returns fieldset that contains fields already known or waiting fields for event with some unknown fields' do
          t = Norikra::Typedef.new({'a' => 'string', 'b' => 'long'})
          t.waiting_fields = ['d']

          r1 = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14'}, true)
          expect(t.datafieldsets.include?(r1)).to be_false

          expect(r1.fields['a'].type).to eql('string')
          expect(r1.fields['b'].type).to eql('long')
          expect(r1.fields['d'].type).to eql('string')
          expect(r1.summary).to eql('a:string,b:long,d:string')

          r2 = t.refer({'a'=>'hoge','b'=>'2000','c'=>'true','d'=>'3.14', 'e' => 'yeeeeeees!'}, true)
          expect(t.datafieldsets.include?(r2)).to be_false

          expect(r2.fields['a'].type).to eql('string')
          expect(r2.fields['b'].type).to eql('long')
          expect(r1.fields['d'].type).to eql('string')
          expect(r2.summary).to eql('a:string,b:long,d:string')
        end
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

      it 'returns hash instance to show fields which contains hash/array fields' do
        t = Norikra::Typedef.new({'a'=>'string','b'=>'long'})
        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long','e.0'=>'string'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long','e.0'=>'string','e.1'=>'long'}))
        t.push(:data, Norikra::FieldSet.new({'a'=>'string','b'=>'long','c'=>'double','f.f1'=>'string'}))
        t.push(:query, Norikra::FieldSet.new({'a'=>'string','b'=>'long','d'=>'string'}))
        fields = t.fields

        r = t.dump
        expect(r.keys.sort).to eql([:a, :b, :c, :d, :e, :f])
        expect(r[:a]).to eql({name: 'a', type: 'string', optional: false})
        expect(r[:b]).to eql({name: 'b', type: 'long', optional: false})
        expect(r[:c]).to eql({name: 'c', type: 'double', optional: true})
        expect(r[:d]).to eql({name: 'd', type: 'string', optional: true})
        expect(r[:e]).to eql({name: 'e', type: 'array', optional: true})
        expect(r[:f]).to eql({name: 'f', type: 'hash', optional: true})
      end
    end
  end
end
