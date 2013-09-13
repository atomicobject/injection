require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rdoc/task'

desc 'Default: run unit specs'
task :default => :spec

desc 'Generate documentation for the injection plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'injection'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
