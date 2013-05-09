require 'pp'

require 'norikra/query'
require 'norikra/output_pool'
require 'norikra/engine'

pool = Norikra::OutputPool.new

query1 = Norikra::Query.new(
  :name => 'OrderEvent over 150 price counts per 10secs',
  :tablename => 'OrderEvent',
  :expression => 'select count(*) AS cnt from OrderEvent.win:time_batch(10 seconds) where price > 150'
)
query2 = Norikra::Query.new(
  :name => 'OrderEvent events with 2 or more count',
  :tablename => 'OrderEvent',
  :expression => 'select * from OrderEvent where count > 1'
)
engine = Norikra::Engine.new(pool)

engine.register(query1)
engine.register(query2)

flag = true

thread = Thread.new do
  while flag
    sleep 1
    results = pool.pop('OrderEvent over 150 price counts per 10secs')
    pp(results) if results.size > 0
    results = pool.pop('OrderEvent events with 2 or more count')
    pp(results) if results.size > 0
  end
end

t = Time.now + 35
while Time.now < t
  3.times do
    engine.send('OrderEvent', [{"itemName"=>"test","price"=>150,"count"=>1}, {"itemName"=>"test","price"=>200,"count"=>1}])
    sleep 3
  end
  engine.send('OrderEvent', [{"itemName"=>"test2","price"=>300,"count"=>'ichi'}])
end

flag = false
thread.join
