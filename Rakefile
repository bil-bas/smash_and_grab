Config = RbConfig if RUBY_VERSION > '1.9.2' # Hack to allow stuff that isn't compatible with 1.9.3 to work.

require 'bundler/setup'
require 'rake/clean'
require 'rake/testtask'
require 'releasy'

require_relative "lib/smash_and_grab/version"

CLEAN.include("*.log")
CLOBBER.include("doc/**/*")

require_relative 'tasks/outline_images'
require_relative 'tasks/create_portraits'
require_relative 'tasks/create_dice'

Releasy::Project.new do
  name "Smash and Grab"
  version SmashAndGrab::VERSION
  executable "bin/smash_and_grab.rbw"
  files `git ls-files`.split("\n")
  files.exclude *%w[.gitignore build/**/*.* raw_media/**/*.* saves/**/*.* test/**/*.* media/icon.* smash_and_grab.gemspec_]

  exposed_files %w[README.md]
  add_link "http://spooner.github.com/games/smash_and_grab", "Smash and Grab website"
  exclude_encoding

  add_build :osx_app do
    wrapper "../releasy/wrappers/gosu-mac-wrapper-0.7.41.tar.gz"
    url "com.github.spooner.games.smash_and_grab"
    icon "media/icon.icns"
    add_package :tar_gz
  end

  add_build :source do
    add_package :zip
  end

  add_build :windows_folder do
    icon "media/icon.ico"
    add_package :exe
  end

  add_build :windows_installer do
    icon "media/icon.ico"
    start_menu_group "Spooner Games"
    readme "README.html"
    add_package :zip
  end

  add_deploy :local do
    path "C:/users/spooner/dropbox/Public/games/smash_and_grab"
  end
end

namespace :gem do
  Bundler::GemHelper.install_tasks
end

desc "Generate Yard docs."
task :yard do
  system "yard doc lib"
end

desc "test"
task :test do
  system "bacon test/**/*_test.rb --quiet"
end

task default: :test

