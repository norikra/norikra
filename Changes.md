# Changes

Changes of norikra.

## v1
* v1.3.1
  * Fix to enable SO_REUSEPORT for listening ports to help "address already in use" exception in restarts
* v1.3.0
  * Esper-5.2 bundle
  * Dependency update for msgpack.gem
  * Dynamic plugin reloading
  * Add experimental `shutoff` mode to reject input data under high memory pressure
  * Fix number of Jetty threads while running to reduce GC troubles under high memory pressure
  * Add `/engine_statistics` API endpoint
  * Add GC statistics in Engine statistics
  * Add `--ui-context-path` option to mount Norikra WebUI atop of path user specified on reverse proxy servers
  * Fix Bug:
    * not to rewrite field names in subqueries (issue #64)
    * not to load stats files containing multibyte characters
* v1.2.2
  * Change API for custom listner plugins (incompatible with 1.2.0, 1.2.1)
* v1.2.1
  * Fix bug to fail to rewrite nullable fields
* v1.2.0
  * Add `NULLABLE(...)` field to query NULL explicitly
  * Pluggable listener and user defined listener gems
  * Fix bug to ignore fields in Esper built-in function
* v1.1.2
  * Enable `-javaagent` option
  * Fix default/pre-set threads
  * Update RSpec dependency to latest
  * Reject field names, starting with numeric characters
  * Reject non-JSON object input events
  * Fix Bug:
    * to show wrong output events from queries
    * missing header column of list of queries in WebUI
* v1.1.1
  * Fix bug not to sort suspended queries correctly
* v1.1.0
  * Add API/WebUI controls to suspend/resume queries
  * Add `STDOUT()` query group to show query result easilly
* v1.0.8:
  * Fix bug not to read command line options for time/route threads
* v1.0.7:
  * Fix bug to set nested values as always required if the first event includes container fields (issue #51)
* v1.0.6:
  * Fix bug not to receive events on '/send' of JSON API
* v1.0.5:
  * Add option `--log4j-properties-path` to specify logger configurations by log4j.properties file
  * Add HTTP RPC headers to allow requests from different origins
  * Fix to deny invalid queries:
    * Queries like `SELECT * FROM ...` are prohibited: Norikra cannot handle these queries
* v1.0.4:
  * Warn if norikra server starts without `--stats` option
* v1.0.3:
  * Fix bug to return Array falsey for Hash output, [] for NULL output
* v1.0.2:
  * Fix bug:
    * to handle encoding of input strings
    * to set encoding of nested output values
    * to handle wrong query groups in error which previously registered
* v1.0.1:
  * String encoding in norikra is fixed as UTF-8
* v1.0.0:
  * Update esper version (4.9.0 -> 5.0.0)
    * Support Group By ROLLUP, Grouping Sets and CUBE
    * Support Group By clause in subqueries
    * Support subqueries that select multiple columns to provide input to enumeration methods
    * Support Having clause to have subquery
  * Add loopback query group to connect query output into targets directly
  * RPC:
    * Add JSON RPC API (/api on port 26578)
    * Add API to fetch norikra server logs
  * Add `--stats-secondary` option to store versioned stats files
  * Fix bug:
    * to return `[]` for NULL query output (fixed to `nil`)
    * to handle container value for simple value field (exception -> NULL)

## v0.1

* v0.1.7:
  * Fix `Pattern` support bug
* v0.1.6:
  * Fix bug: Wrong escape for java instance method calls
* v0.1.5:
  * Add RPC port monitoring handler (GET /)
  * Add `Pattern` support
  * Changes for GC/JVM
    * Server starts with default(recommended) JVM options for GC configurations
    * Add option not to use default JVM options
    * Add option to configure JVM to print GC logs
  * Stats file changes
    * Changed to use SIGUSR2 (SIGUSR1 is used by JVM on linux platform)
    * Changed no to contain server process configurations (ports, threads, logs ...)
  * WebUI improvements
    * Add button to close target on WebUI
    * Add link to download stats file
  * Fix bugs
    * Fieldname handlings about names with non-alphabetic chars
    * Query parser bug for some built-in functions (ex: `rate(10)`)
    * Write stats file in more safe way
    * WebUI: Incorrect memory bar
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
