# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "cassandra-queue/version"

Gem::Specification.new do |s|
  s.name        = "cassandra-queue"
  s.version     = CassandraQueue::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay Bhat"]
  s.email       = ["jbhat@ooyala.com"]
  s.homepage    = "http://www.ooyala.com"
  s.summary     = %q{Cassandra-backed general queue}
  s.description = <<EOS
Cassandra Queue is a queue that uses cassandra as a backend, that can hopefully be used
as either a Job Queue, or a Message queue.
EOS

  s.rubyforge_project = "cassandra-queue"

  ignores = File.readlines(".gitignore").grep(/\S+/).map {|pattern| pattern.chomp }
  dotfiles = Dir[".*"]
  s.files = Dir["**/*"].reject {|f| File.directory?(f) || ignores.any? {|i| File.fnmatch(i, f) } } + dotfiles
  s.test_files = s.files.grep(/^test\//)

  s.require_paths = ["lib"]

  s.add_dependency "cassandra"

  s.add_development_dependency "bundler", "~> 1.0.10"
  s.add_development_dependency "scope", "~> 0.2.1"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rake"
end
