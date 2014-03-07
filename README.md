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

Run tests faster than 2 or more times:

1. execute `spork`
1. execute `script/spec_server_pry` in another terminal
1. run `rspec` in pry console (executed fastly after second times)

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

## Events and Queries

See: http://norikra.github.io/

## Changes

* v0.1.4:
 * Stat dump option on runtime per specified intervals (`--dump-stat-interval`)
 * Stat dump on demand by SIGUSR1
 * `norikra-client event see` command (and API call) to get query results, but not remove it
 * Last modified time for each target on WebUI
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
