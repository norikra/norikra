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
* rvm: https://rvm.io/rvm/install/
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

## User Defined Functions

UDFs/UDAFs can be loaded as plugin gems over rubygems or as private plugins. For example, see 'norikra-udf-mock' repository.

TBD

## Performance

Threads option available with command line options.

TBD

## Versions

* v0.1.0:
 * First release for production
* v0.1.1:
 * Fix types more explicitly for users ('int/long' -> 'integer', 'float/double' -> 'float')

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * GPLv2
