require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:test) do |t|
  t.rspec_opts = ["-c", "-f progress"] # '--format specdoc'
  t.pattern = 'spec/**/*_spec.rb'
end

task :test => :spec
task :default => :spec
