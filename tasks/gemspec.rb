# -*- encoding: utf-8 -*-

GEMSPEC_FILE =
task :gemspec do
  generate_gemspec
end

file "smash_and_grab.gemspec" do
  generate_gemspec
end

def generate_gemspec
  puts "Generating gemspec"

  require_relative "../lib/smash_and_grab/version"

  spec = Gem::Specification.new do |s|
    s.name = "smash_and_grab"
    s.version = SmashAndGrab::VERSION

    s.platform    = Gem::Platform::RUBY
    s.authors     = ["Bil Bas (Spooner)"]
    s.email       = ["bil.bagpuss@gmail.com"]
    s.homepage    = "http://spooner.github.com/games/smash_and_grab/"
    s.summary     = %q{Turn-based isometric heist game}
    s.description = <<END
#{s.summary}
END

    s.files = Dir[*%w<bin/**/* config/**/* lib/**/* media/**/* *.md *.txt>]
    s.licenses = ["MIT"]
    s.rubyforge_project = s.name

    s.executable = s.name
    s.test_files = Dir["test/**/*_test.rb"]
    s.required_ruby_version = "~> 1.9.2"

    s.add_runtime_dependency "gosu", "~> 0.7.41"
    s.add_runtime_dependency "chingu", "~> 0.9rc7"
    s.add_runtime_dependency "fidgit", "~> 0.2.1"
    s.add_runtime_dependency "texplay", "~> 0.3"
    s.add_runtime_dependency "r18n-desktop", "~> 0.4.14"

    s.add_development_dependency "releasy", "~> 0.2.2"
    s.add_development_dependency "rake", "~> 0.9.2.2"
    s.add_development_dependency "bacon-rr", "~> 0.1.0"
  end

  File.open("#{spec.name}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end