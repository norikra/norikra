require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["-c", "-f progress"] # '--format specdoc'
  t.pattern = 'spec/**/*_spec.rb'
end

task :devstart do |t|
  require 'pathname'
  libs = ['lib', 'esper'].map{|p| Pathname.new(__FILE__).dirname.join('.', p).expand_path}
  $LOAD_PATH.unshift(*libs.map(&:to_s))

  ARGV.clear
  ARGV.push("start", "--more-verbose", "-Xmx1500m", "--stats", "dump.json")
  require 'norikra/cli'
  Norikra::CLI.start
end

task :test => :spec
task :default => :spec
