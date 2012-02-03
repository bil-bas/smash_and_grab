Config = RbConfig if RUBY_VERSION > '1.9.2' # Hack to allow stuff that isn't compatible with 1.9.3 to work.

def require_folder(path, files)
  files.each do |file|
    if path.empty?
      require_relative file
    else
      require_relative File.join(path, file)
    end
  end
end

t = Time.now

begin
  require 'rubygems' unless defined? OSX_EXECUTABLE
rescue LoadError
end

begin
  require 'bundler/setup' unless defined?(OSX_EXECUTABLE) or ENV['OCRA_EXECUTABLE']

rescue LoadError
  $stderr.puts "Bundler gem not installed. To install:\n  gem install bundler"
  exit
rescue Exception
  $stderr.puts "Gem dependencies not met. To install:\n  bundle install"
  exit
end

require 'syck' # Required for unknown reason, when ocraed!

require 'gosu'
require_folder('gosu_ext', %w[font])

require 'chingu'

require 'fidgit'
Fidgit::Element.schema.merge_schema! YAML.load(File.read(File.expand_path('config/gui/schema.yml', EXTRACT_PATH)))
require_folder("fidgit_ext", %w[element cursor])

require 'texplay'
require_folder('texplay_ext', %w[color image window])
TexPlay.set_options(caching: false)

include Gosu
Font.factor_stored = 1
Font.factor_rendered = 1.0 / Font.factor_stored
include Chingu

# Setup Chingu's autoloading media directories.
media_dir = File.expand_path('media', EXTRACT_PATH)
Image.autoload_dirs.unshift File.join(media_dir, 'images')
Sample.autoload_dirs.unshift File.join(media_dir, 'sounds')
Song.autoload_dirs.unshift File.join(media_dir, 'music')
Font.autoload_dirs.unshift File.join(media_dir, 'fonts')

require_folder "std_ext", %w[array hash]

# Include other files.
require_folder("", %w[log version sprite_sheet z_order z_order_recorder game_window mouse_selection])
require_folder("gui", %w[minimap editor_selector entity_summary info_panel])
require_folder("map", %w[tile wall map])
require_folder("objects", %w[static entity vehicle])
require_folder("states", %w[edit_level play_level main_menu])
require_folder("players", %w[player])
require_folder("history", %w[editor_action_history game_action_history])

SmashAndGrab::Log.log.debug { "Scripts loaded in #{"%.3f" % (Time.now - t)} s" }

SmashAndGrab::GameWindow.new

unless defined? Ocra or defined? Bacon
  $window.show
end
