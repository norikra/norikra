require_relative './spec_helper'

require 'norikra/typedef_manager'

require 'norikra/typedef'

describe Norikra::TypedefManager do
  context 'is instanciated without any options' do
    it 'is non-strict mode' do
      Norikra::TypedefManager.new.strict_check.should be_false
    end
  end

  context 'is instanciated as non-strict' do
    describe '#refer'do
      context 'called with single event object' do
        it 'returns typedef array with single content' do
          m = Norikra::TypedefManager.new
          defs = m.refer([
              {'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'},
            ])
          defs.size.should eql(1)
          defs[0].should eq(Norikra::Typedef.guess({'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'}))
        end
      end

      context 'called with 2 or more event objects' do
        it 'returns typedef array with 2 members from first-and-last events definition variation' do
          m = Norikra::TypedefManager.new
          defs = m.refer([
              {'name'=>'tagomoris', 'age'=>33},
              {'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'},
              {'name'=>'tagomori3104', 'age'=>'33', 'sex'=>'male'},
            ])
          defs.size.should eql(2)
          defs[0].should eq(Norikra::Typedef.guess({'name'=>'tagomoris', 'age'=>33}))
          defs[1].should eq(Norikra::Typedef.guess({'name'=>'tagomori3104', 'age'=>'33', 'sex'=>'male'}))
        end
      end
    end
  end

  context 'is instanciated as strict' do
    it 'is strict mode' do
      Norikra::TypedefManager.new(:strict => true).strict_check.should be_true
    end

    describe '#refer'do
      context 'called with 2 or more event objects' do
        it 'returns typedef array with members as same as events definition variation' do
          m = Norikra::TypedefManager.new(:strict => true)
          defs = m.refer([
              {'name'=>'tagomoris', 'age'=>33},
              {'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'},
              {'name'=>'tagomori3104', 'age'=>'33', 'sex'=>'male'},
            ])
          defs.size.should eql(3)
          defs[0].should eq(Norikra::Typedef.guess({'name'=>'tagomoris', 'age'=>33}))
          defs[1].should eq(Norikra::Typedef.guess({'name'=>'tagomori satoshi', 'age'=>33, 'sex'=>'male','lang'=>'ja'}))
          defs[2].should eq(Norikra::Typedef.guess({'name'=>'tagomori3104', 'age'=>'33', 'sex'=>'male'}))
        end
      end
    end
  end
end
