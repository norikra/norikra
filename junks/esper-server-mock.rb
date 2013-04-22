require 'pp'

require 'norikra/query'
require 'norikra/output_pool'
require 'norikra/engine'

pool = Norikra::OutputPool.new
query = Norikra::Query.new(
  :tablename => 'OrderEvent',
  :typedef => {:name => 'string', :price => 'double'},
  :expression => 'select count(*) AS cnt from OrderEvent.win:time_batch(10 seconds) where cast(price,double) > 150'
)
engine = Norikra::Engine.new(pool)
engine.register(query)

flag = true

thread = Thread.new do
  while flag
    sleep 1
    results = pool.pop('OrderEvent')
    pp(results) if results.size > 0
  end
end

t = Time.now + 35
while Time.now < t
  engine.send('OrderEvent', [{"itemName"=>"test","price"=>150}, {"itemName"=>"test","price"=>200}])
  sleep 3
end

flag = false
thread.join

