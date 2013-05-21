#!/usr/bin/env jruby

require 'java'
require 'esper/esper-4.9.0.jar'
require 'esper/esper/lib/commons-logging-1.1.1.jar'
require 'esper/esper/lib/antlr-runtime-3.2.jar'
require 'esper/esper/lib/cglib-nodep-2.2.jar'
require 'pp'

# Lets get the epService provider
ep_service = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider

# And the configuration
ep_config = ep_service.getEPAdministrator.getConfiguration

class BaseListener
  include com.espertech.esper.client.UpdateListener
  def initialize(name)
    @name = name
  end
  def update(newEvents, oldEvents)
    puts "#{@name} #{Time.now}: " + newEvents.map{|e| e.getUnderlying.inspect}.join(' ')
  end
end

# Create an unmatched listener
class UnmatchedListener
  include com.espertech.esper.client.UnmatchedListener

  def update(event)
    # puts "unmatched:\n- " + event.getProperties.inspect
    # ignore
  end
end

# Prepare the OrderEvent type
base = {
  "itemName" => "string",
  "price" => "double"
}
ep_config.addEventType('b_test', base)

ep_config.addEventType('q_test1', base, ['b_test'].to_java(:string))
query1 = "SELECT count(*) AS cnt FROM q_test1.win:time_batch(3 seconds) WHERE price > 1.0"
ep_service.getEPAdministrator.createEPL(query1).addListener(BaseListener.new('q_test1'))

ep_config.addEventType('q_test2', base.merge({'amount' => 'int'}), ['b_test'].to_java(:string))
query2 = "SELECT count(*) AS cnt FROM q_test2.win:time_batch(3 seconds) WHERE price > 1.0 AND amount > 1"
ep_service.getEPAdministrator.createEPL(query2).addListener(BaseListener.new('q_test2'))

ep_service.getEPRuntime.setUnmatchedListener(UnmatchedListener.new)

# And finally process the event
epr_runtime = ep_service.getEPRuntime

ep_config.addEventType('e_v1', base, ['q_test1', 'b_test'].to_java(:string))
ep_config.addEventType('e_v2', base, ['q_test2', 'q_test1', 'b_test'].to_java(:string))

t = Time.now + 15
while Time.now < t
  epr_runtime.sendEvent({"itemName"=>"test","price"=>100}, "e_v1")
  epr_runtime.sendEvent({"itemName"=>"test","amount"=>1,"price"=>300}, "e_v2")
  epr_runtime.sendEvent({"itemName"=>"test","amount"=>2,"price"=>300}, "e_v2")
  epr_runtime.sendEvent({"itemName"=>"test","price"=>200}, "e_v1")
  epr_runtime.sendEvent({"itemName"=>"test","amount"=>3,"price"=>300}, "e_v2")
  sleep 1
end
