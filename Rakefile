Config = RbConfig if RUBY_VERSION > '1.9.2' # Hack to allow stuff that isn't compatible with 1.9.3 to work.

require 'rake/clean'

require_relative "lib/version"
APP = "smash_and_grab"
APP_READABLE = "Smash and Grab"
RELEASE_VERSION = SmashAndGrab::VERSION

OSX_GEMS = %w[chingu fidgit clipboard] # Source gems for inclusion in the .app package.

#LICENSE_FILE = "COPYING.txt"

# My scripts which help me package games.
require_relative "../release_packager/lib/release_packager"

CLEAN.include("*.log")
CLOBBER.include("doc/**/*")

require_relative 'build/outline_images'
require_relative 'build/create_portraits'

desc "Generate Yard docs."
task :yard do
  system "yard doc lib"
end

desc "Run all tests"
task :test do
  begin
    ruby File.expand_path("test/run_all.rb", File.dirname(__FILE__))
  rescue
    exit 1
  end
end

