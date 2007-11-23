require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the injection plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the injection plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'injection'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Generate and upload api homepage and docs to rubyforge"
task :upload_doc => :rerdoc do
  user = ENV['user'] || "alles"
	sh "scp -r doc/* #{user}@rubyforge.org:/var/www/gforge-projects/atomicobjectrb/injection/doc/"
	sh "rm -rf doc"

  temp = "homepage_send"
  rm_rf temp
  mkdir temp
  cp ["homepage/index.html", "homepage/page_header.png", "homepage/coconut.png", "homepage/coconut_test.png" ], temp
	sh "scp -r #{temp}/* #{user}@rubyforge.org:/var/www/gforge-projects/atomicobjectrb/injection/"
	rm_rf temp
end

desc "Release from current trunk"
task :release => :upload_doc do
  user = ENV['user'] || "alles"
	version = ENV['version']
	raise "Please specify version" unless version

	require 'fileutils'
	include FileUtils::Verbose
	proj_root = File.expand_path(File.dirname(__FILE__))
	begin 
		cd proj_root

		sh 'svn up'
		status = `svn status` 
		raise "Please clean up before releasing.\n#{status}" unless status == ""

    sh "svn cp . svn+ssh://#{user}@rubyforge.org/var/svn/atomicobjectrb/tags/injection/rel-#{version} -m 'Releasing version #{version}'"
		sh "svn cp . svn+ssh://#{user}@rubyforge.org/var/svn/atomicobjectrb/tags/injection-#{version} -m 'Updating stable tag to version #{version}'"

		rm_rf 'release'
		mkdir 'release'
		sh "svn export . release/injection-#{version}"
		cd 'release'
		sh "tar cvzf ../injection-#{version}.tar.gz injection-#{version}"
	ensure
		cd proj_root
		rm_rf 'release'
	end
end
