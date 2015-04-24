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

### Install and launch

See: http://norikra.github.io/

### How to execute norikra server and tests in development

Fix code and tests:

1. clone this repository
1. run `bundle install` w/ jruby
1. add/fix spec in `spec/*_spec.rb`
1. fix code in `lib`
1. run `bundle exec rake`

Execute norikra server with target/query continuation:

1. `bundle exec rake devserver`
1. `Ctrl-C` and re-execute for updated code

## Clients

Use `norikra-client` cli command. These are available on both of JRuby and CRuby.

https://rubygems.org/gems/norikra-client
https://rubygems.org/gems/norikra-client-jruby

And the client library for application developers are also included in these gems.

https://github.com/norikra/norikra-client-ruby

For other languages:
 * Perl: https://github.com/norikra/norikra-client-perl
 * Python: https://github.com/norikra/norikra-client-python

## Events and Queries

See: http://norikra.github.io/

## Changes

* v1.3
  * Dynamic plugin reloading by SIGHUP
  * Esper-5.2 bundle
  * Dependency update for msgpack.gem
* v1.2
  * `NULLABLE()` fields
  * Pluggable listeners
* v1.1
  * Suspend/Resume queries
* v1.0
  * Esper-5.0 bundle
  * Pattern support
  * Nested object support
  * Built-in default JVM options
  * JSON APIs
  * Many more features
* v0.1
  * First release for production usage

See Changes.md for details.

## Copyright

* Copyright (c) 2013- TAGOMORI Satoshi (tagomoris)
* License
  * GPLv2
