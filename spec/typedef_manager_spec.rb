require_relative './spec_helper'

require 'norikra/typedef_manager'

require 'norikra/typedef'

describe Norikra::TypedefManager do
  context 'is just instanciated' do
    describe '#refer'do
      context 'called with data' do
        it 'returns typedef object, which is same as result of Typedef.simple_guess' do
          m = Norikra::TypedefManager.new
          r = m.refer('tablename', {
              'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja',
            })
          expect(r).to eq(Norikra::Typedef.simple_guess({'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'}))
        end
      end

      context 'called sometimes' do
        it 'returns typedef object, which affected by previous data' do
          m = Norikra::TypedefManager.new
          r = m.refer('tablename', {
              'name'=>'tagomori satoshi', 'age'=>'33', 'sex'=>'male', 'lang'=>'ja',
            })
          expect(r).to eq(Norikra::Typedef.simple_guess({'name'=>'tagomori satoshi', 'age'=>'33', 'sex'=>'male', 'lang'=>'ja'}))

          r = m.refer('tablename', {
              'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja',
            })
          expect(r).to_not eq(Norikra::Typedef.simple_guess({'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'}))
          expect(r).to eq(Norikra::Typedef.simple_guess({'name'=>'tagomori satoshi', 'age'=>'33', 'sex'=>'male', 'lang'=>'ja'}))
        end
      end
    end
  end

  context 'with set of pre stored typedefs' do
    m = Norikra::TypedefManager.new
    m.store('tablename', Norikra::Typedef.new(:definition => {'age'=>'string','name'=>'string','sex'=>'string','lang'=>'string'}))

    describe '#refer'do
      context 'called with data' do
        it 'returns typedef object, which was stored previously' do
          r = m.refer('tablename', {
              'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja',
          })
          expect(r.definition['age']).to eql('string')
        end
      end
    end
  end
end
