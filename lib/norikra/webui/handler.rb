require 'norikra/error'
require 'norikra/logger'
include Norikra::Log

require 'norikra/webui'

require 'sinatra/base'

class Norikra::WebUI::Handler < Sinatra::Base
  set :public_folder, File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'public'))
  set :views, File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'views'))

  def self.engine=(engine)
    @@engine = engine
  end

  def logging(type, handler, *args)
    if type == :manage
      debug "WebUI", :handler => handler.to_s, :args => args
    else
      trace "WebUI", :handler => handler.to_s, :args => args
    end
  end

  def engine; @@engine; end

  def targets
    engine.targets.map(&:name)
  end

  get '/' do
    logging :show, :index
    @page = "summary"

    queries = engine.queries.sort
    pooled_events = Hash[* queries.map{|q| [q.name, engine.output_pool.pool.fetch(q.name, []).size.to_s]}.flatten]

    engine_targets = engine.targets.sort
    targets = engine_targets.map{|t| {name: t.name, auto_field: t.auto_field, fields: engine.typedef_manager.field_list(t.name) }}

    erb :index, :layout => :base, :locals => { stat: engine.statistics, queries: queries, pool: pooled_events, targets: targets }
  end
end
