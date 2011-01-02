# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "injection/version"

Gem::Specification.new do |s|
  s.name        = "injection"
  s.version     = Injection::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Atomic Object"]
  s.email       = ["github@atomicobject.com"]
  s.homepage    = "https://github.com/atomicobject/injection"
  s.summary     = %q{Dependency injection for Rails controllers and observers}
  s.description = %q{Injection is a simple dependency injection gem for rails3. It allows you to inject objects into your controllers and observers which have been described in a yaml file (config/objects.yml).}

  s.rubyforge_project = "injection"

  s.files         = `git ls-files`.split("\n").reject {|f| f =~ /homepage/}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "rails", ["~> 3"]
  s.add_dependency "diy", ["~> 1"]
  s.add_dependency "constructor", ["~> 2"]
  
  s.add_development_dependency "rspec-rails", "~> 2"
  s.add_development_dependency "sqlite3-ruby"
end
