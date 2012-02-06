# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "smash_and_grab/version"

Gem::Specification.new do |s|
  s.name = "Smash and Grab"
  s.version = SmashAndGrab::VERSION

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bil Bas (Spooner)"]
  s.email       = ["bil.bagpuss@gmail.com"]
  s.homepage    = "http://spooner.github.com/games/smash_and_grab/"
  s.summary     = %q{Turn-based isometric heist game}
  s.description = <<END
#{s.summary}
END

  s.files = `git ls-files`.split("\n").reject {|f| f =~ /^(?:\.|raw_media|build)/ }
  s.licenses = ["MIT"]
  s.rubyforge_project = "smash_and_grab"

  s.executable = "smash_and_grab"
  s.test_files = Dir["test/**/*_test.rb"]
  s.required_ruby_version = "~> 1.9.2"

  s.add_runtime_dependency "gosu", "~> 0.7.41"
  s.add_runtime_dependency "chingu", "~> 0.9rc7"
  s.add_runtime_dependency "fidgit", "~> 0.2.0"
  s.add_runtime_dependency "texplay", "~> 0.3"
  #s.add_runtime_dependency "r18n-desktop", "~> 0.4.9"

  s.add_development_dependency "releasy", "~> 0.2.2"
  s.add_development_dependency "rake", "~> 0.9.2.2"
  s.add_development_dependency "bacon-rr", "~> 0.1.0"
end