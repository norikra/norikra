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

def add_epl(service, config, tablename, typedef, expression, listener)
  config.addEventType(tablename, typedef)
  service.getEPAdministrator.createEPL(expression).addListener(listener)
end

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
order_event_type = {
  "itemName" => "string",
  "price" => "double"
}

# Create EPL expression
### select avg(price) from StockTick.win:time(30 sec) where symbol='IBM'
### #expression = "select avg(price) from OrderEvent"
add_epl(ep_service, ep_config, 'OrderEvent', order_event_type,
        "select count(*) AS cnt from OrderEvent.win:time_batch(10 seconds) where cast(price,double) > 150", BaseListener.new('x1'))
add_epl(ep_service, ep_config, 'OrderEvent', order_event_type,
        "select count(*) AS cnt from OrderEvent.win:time_batch(10 seconds) where cast(price,double) > 210", BaseListener.new('x2'))
ep_service.getEPRuntime.setUnmatchedListener(UnmatchedListener.new)

# And finally process the event
epr_runtime = ep_service.getEPRuntime

t = Time.now + 15
while Time.now < t
  epr_runtime.sendEvent({"itemName"=>"test","price"=>100}, "OrderEvent")
  epr_runtime.sendEvent({"itemName"=>"test","price"=>200}, "OrderEvent")
  epr_runtime.sendEvent({"itemName"=>"test","price"=>300}, "OrderEvent")
  sleep 3
end

add_epl(ep_service, ep_config, 'OrderEvent', order_event_type,
        "select count(*) AS cnt from OrderEvent.win:time_batch(10 seconds) where cast(price,double) > 50", BaseListener.new('x3'))

t = Time.now + 35
while Time.now < t
  epr_runtime.sendEvent({"itemName"=>"test","price"=>100}, "OrderEvent")
  epr_runtime.sendEvent({"itemName"=>"test","price"=>200}, "OrderEvent")
  epr_runtime.sendEvent({"itemName"=>"test","price"=>300}, "OrderEvent")
  sleep 3
end
