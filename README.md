# Norikra

'Norikra' is a CEP server implementation, based on Esper Java CEP Library, and have RPC handler over http.

'Norikra' provides basic features of Esper over RPC, and more flexible fields definition of event streams.

* 2 or more different field sets with one abstract stream name (called 'target' in norikra)
* query against 'target', not streams
  * queries will be executed with events in target, that have fields required for query
* output event pool
  * you can fetch events when you want
  * streaming fetch connection (in future)

And, easy to install/execute dramatically, and more, fully open source software.

## Install and Execute

On JRuby environment, do these command (and, that all):

    gem install norikra

To execute:

    norikra

For JRuby installation, you can use `rbenv`, `rvm` and `xbuild`, or install JRuby directly.

* JRuby: http://jruby.org/
* rbenv: https://github.com/sstephenson/rbenv/
* rvm: https://rvm.io/rvm/install/
* xbuild: https://github.com/tagomoris/xbuild

### Command line options

To start norikra server:

    norikra start

JVM options like `-Xmx` are available before norikra subcommand:

    norikra -Xmx500m start

TBD (you can use `norikra -h`)

## Clients

Use `Norikra::Client` and `norikra-client` cli command. These are available on both of JRuby and CRuby.

https://github.com/tagomoris/norikra-client

## Events and Queries

For example, think about event streams related with one web service (ex: 'www'). At first, define `target` with mandantory fields (in other words, minimal fields set for variations of 'www' events).

    norikra-client target add www path:string status:integer referer:string agent:string userid:integer
    norikra-client target list

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

## Versions

TBD

## TODO

* daemonize
* performance parameters
* query unregister

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * GPL v2
