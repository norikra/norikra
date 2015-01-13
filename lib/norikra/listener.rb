require 'java'
require 'esper-5.0.0.jar'
require 'esper/lib/commons-logging-1.1.3.jar'
require 'esper/lib/antlr-runtime-4.1.jar'
require 'esper/lib/cglib-nodep-3.1.jar'

require 'norikra/field'
require 'norikra/query'

require 'json'

module Norikra
  class Listener
    include com.espertech.esper.client.UpdateListener

    def initialize(query_name, query_group, output_pool, events_statistics)
      @query_name = query_name
      @query_group = query_group
      @output_pool = output_pool
      @events_statistics = events_statistics
    end

    def type_convert(value)
      if value.respond_to?(:getUnderlying)
        value = value.getUnderlying
      end

      trace "converting", value: value

      if value.nil?
        value
      elsif value.respond_to?(:to_hash)
        Hash[ value.to_hash.map{|k,v| [ Norikra::Field.unescape_name(k), type_convert(v)] } ]
      elsif value.respond_to?(:to_a)
        value.to_a.map{|v| type_convert(v) }
      elsif value.respond_to?(:force_encoding)
        value.force_encoding('UTF-8')
      else
        value
      end
    end

    def update(new_events, old_events)
      t = Time.now.to_i
      events = new_events.map{|e| [t, type_convert(e)]}
      trace "updated event", query: @query_name, group: @query_group, event: events
      @output_pool.push(@query_name, @query_group, events)
      @events_statistics[:output] += events.size
    end
  end

  class LoopbackListener < Listener
    def initialize(engine, query_name, query_group, events_statistics)
      @engine = engine
      @query_name = query_name
      @query_group = query_group
      @events_statistics = events_statistics
      @loopback_target = Norikra::Query.loopback(query_group)
    end

    def update(new_events, old_events)
      event_list = new_events.map{|e| type_convert(e) }
      trace "loopback event", query: @query_name, group: @query_group, event: event_list
      @events_statistics[:output] += event_list.size
      #
      # We does NOT convert 'container.$0' into container['field'].
      # Use escaped names like 'container__0'. That is NOT so confused.
      @engine.send(@loopback_target, event_list)
    end
  end

  class StdoutListener < Listener
    def initialize(engine, query_name, query_group, events_statistics)
      raise "BUG: query group is not 'STDOUT()'" unless query_group == 'STDOUT()'

      @engine = engine
      @query_name = query_name
      @query_group = query_group
      @events_statistics = events_statistics

      @stdout = STDOUT
    end

    def update(new_events, old_events)
      event_list = new_events.map{|e| type_convert(e) }
      trace "stdout event", query: @query_name, event: event_list
      @events_statistics[:output] += event_list.size

      event_list.each do |e|
        @stdout.puts @query_name + "\t" + JSON.dump(e)
      end
    end
  end

  ##### Unmatched events are simply ignored
  # class UnmatchedListener
  #   include com.espertech.esper.client.UnmatchedListener
  #   def update(event)
  #     # puts "unmatched:\n- " + event.getProperties.inspect
  #     # ignore
  #   end
  # end
end
