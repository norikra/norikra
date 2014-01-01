# Norikra

Norikra is an open-source Stream Processing Server with SQL.
 * Schema-less event streams (called as 'target')
 * SQL processing with window specifier supports, and JOINs, SubQueries
 * Complex input/output events with nested Hashes and Arrays, and Query supports
 * Dynamic query registration/removing, without any restarts
 * Ultra fast bootstrap and small start
 * UDF plugins

## Install and Execute

On JRuby environment, do these command (and, that all):

    gem install norikra

To execute:

    norikra start

For JRuby installation, you can use `rbenv`, `rvm` and `xbuild`, or install JRuby directly.

* JRuby: http://jruby.org/
* rbenv: https://github.com/sstephenson/rbenv/
* xbuild: https://github.com/tagomoris/xbuild

### Command line options

To start norikra server in foreground:

    norikra start

Norikra server doesn't save targets/queries in default.
Specify `--stats STATS_FILE_PATH` option to save these runtime configuration automatically.

    norikra start --stats /path/to/data/norikra.stats.json

JVM options like `-Xmx` are available:

    norikra start -Xmx2g

To daemonize:

    norikra start -Xmx2g --daemonize --logdir=/var/log/norikra
    norikra start -Xmx2g --daemonize --pidfile /var/run/norikra.pid --logdir=/var/log/norikra
    # To stop
    norikra stop

Performance options about threadings:

    norikra start --micro     # or --small, --middle, --large

For other options, see help:

    norikra help start

### How to execute norikra server and tests in development

Fix code and tests:

1. clone this repository
1. run `bundle install` w/ jruby
1. add/fix spec in `spec/*_spec.rb`
1. fix code in `lib`
1. run `bundle exec rake`

Run tests faster than 2 or more times:

1. execute `spork`
1. execute `script/spec_server_pry` in another terminal
1. run `rspec` in pry console (executed fastly after second times)

Execute norikra server with target/query continuation:

1. `bundle exec rake devserver`
1. `Ctrl-C` and re-execute for updated code

## Clients

Use `Norikra::Client` and `norikra-client` cli command. These are available on both of JRuby and CRuby.

https://github.com/norikra/norikra-client-ruby

For other languages:
 * Perl: https://github.com/norikra/norikra-client-perl

## Events and Queries

For example, think about event streams related with one web service (ex: 'www'). At first, define `target` with mandantory fields (in other words, minimal fields set for variations of 'www' events).

    norikra-client target open www path:string status:integer referer:string agent:string userid:integer
    norikra-client target list

Supported types are `string`, `boolean`, `integer`, `float` and `hash`, `array`.

You can register queries when you want.

    # norikra-client query add QUERY_NAME  QUERY_EXPRESSION
    norikra-client query add www.toppageviews 'SELECT count(*) AS cnt FROM www.win:time_batch(10 sec) WHERE path="/" AND status=200'

And send events into norikra (multi line events [json-per-line] and LTSV events are also allowed).

    echo '{"path":"/", "status":200, "referer":"", "agent":"MSIE", "userid":3}' | norikra-client event send www
    echo '{"path":"/login", "status":301, "referer":"/", "agent":"MSIE", "userid":3}' | norikra-client event send www
    echo '{"path":"/content", "status":200, "referer":"/login", "agent":"MSIE", "userid":3}' | norikra-client event send www
    echo '{"path":"/page/1", "status":200, "referer":"/content", "agent":"MSIE", "userid":3}' | norikra-client event send www

Finally, you can get query outputs:

    norikra-client event fetch www.toppageviews
	{"time":"2013/05/15 15:10:35","cnt":1}
	{"time":"2013/05/15 15:10:45","cnt":0}

You can just add queries with optional fields:

    norikra-client query add www.search 'SELECT count(*) AS cnt FROM www.win:time_batch(10 sec) WHERE path="/content" AND search_param.length() > 0'

And send more events:

    echo '{"path":"/", "status":200, "referer":"", "agent":"MSIE", "userid":3}' | norikra-client event send www
    echo '{"path":"/", "status":200, "referer":"", "agent":"Firefox", "userid":4}' | norikra-client event send www
    echo '{"path":"/content", "status":200, "referer":"/login", "agent":"MSIE", "userid":3}' | norikra-client event send www
    echo '{"path":"/content", "status":200, "referer":"/login", "agent":"Firefox", "userid":4, "search_param":"news worldwide"}' | norikra-client event send www

Query 'www.search' matches the last event automatically.

## Performance

Threads option available with `norikra start`. Simple specifiers for performance with threadings:

    norikra start --micro     # or --small, --middle, --large (default: 'micro')

Norikra server has 3 types of threads:

* engine: 4 query engine thread types on Esper
  * inbound: input data handler for queries
  * outbound: output data handler for queries
  * router: event handler which decides which query needs that events
  * timer: executer for queries with time_batches and other timing events
* rpc: data input/output rpc handler threads on Jetty
* web: web ui request handler threads on Jetty

In many cases, norikra server handling high rate events needs large number of rpc threads to handle input/output rpc requests. WebUI don't need threads rather than default in almost all of cases.

Engine threads depends on queries running on norikra, input/output event data rate and target numbers. For more details, see Esper's API Documents: http://esper.codehaus.org/esper-4.10.0/doc/reference/en-US/html/api.html#api-threading

Norikra's simple specifiers details of threadings are:

* micro: development and testing
  * engine: all processings on single threads
  * rpc: 2 threads
  * web: 2 threads
* small: low rate events on virtual servers
  * engine: inbound 1, outbound 1, route 1, timer 1 threads
  * rpc: 2 threads
  * web: 2 threads
* middle: high rate events on physical servers
  * engine: inbound 4, outbound 2, route 2, timer 2 threads
  * rpc: 4 threads
  * web: 2 threads
* large: inbound heavy traffic and huge amount of queries
  * engine: inbound 6, outbound 6, route 4, timer 4 threads
  * rpc: 8 threads
  * web: 2 threads

To specify sizes of each threads, use `--*-threads=NUM` options. For more details, see: `norikra help start`.

## User Defined Functions

UDFs/UDAFs can be loaded as plugin gems over rubygems or as private plugins.
In fact, Norikra's UDFs/UDAFs are Esper's plugin with a JRuby class to indicate plugin metadata.

For details how to write your own UDF/UDAF for norikra and to release it as gem, see README of `norikra-udf-mock`.
https://github.com/norikra/norikra-udf-mock

## Changes

* v0.1.3:
 * Fix critical bug about query de-registration
* v0.1.2:
 * Fix CLI start command to detect jruby path collectly (behind rbenv/rvm and others)
* v0.1.1:
 * Fix types more explicitly for users ('int/long' -> 'integer', 'float/double' -> 'float')
* v0.1.0:
 * First release for production

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * GPLv2
