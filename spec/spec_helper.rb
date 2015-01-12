require 'rubygems'

require 'rubygems'
require 'rspec'
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../esper')

require 'norikra/logger'

$dummylogger = Norikra::DummyLogger.new
Norikra::Log.init('test', nil, {:logger => $dummylogger})

require 'norikra/engine'

$running = {}

module Norikra::SpecHelper
  def logger ; $dummylogger ; end
  def engine_start
    service = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider
    administrator = service.getEPAdministrator
    config = administrator.getConfiguration
    runtime = service.getEPRuntime
    $running = {
      service: service,
      administrator: administrator,
      config: config,
      runtime: runtime,
    }
  end
  def engine_stop
    administrator.stopAllStatements
    $running = {}
  end
  def with_engine
    engine_start
    val = yield
    engine_stop
    val
  end
  def service ; $running[:service] ; end
  def config ; $running[:config] ; end
  def runtime ; $running[:runtime] ; end
  def administrator ; $running[:administrator] ; end
end
