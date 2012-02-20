Config = RbConfig if RUBY_VERSION > '1.9.2' # Hack to allow stuff that isn't compatible with 1.9.3 to work.

require 'bundler/setup'
require 'rake/clean'
require 'rake/testtask'
require 'releasy'

require_relative "lib/smash_and_grab/version"

CLEAN.include("*.log")
CLOBBER.include("doc/**/*")

Dir['tasks/**'].each {|f| import f }

namespace :gem do
  Bundler::GemHelper.install_tasks
end
task "gem:build" => :gemspec
task "gem:install" => :gemspec

desc "Generate Yard docs."
task :yard do
  system "yard doc lib"
end

desc "test"
task :test do
  system "bacon test/**/*_test.rb --quiet"
end

task default: :test

