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

module SmashAndGrab
  SAVE_PATH = File.join(USER_DATA_PATH, "saves")
end

require_relative "log"
SmashAndGrab::Log.log.info { "Smash and Grab loading; please wait.." }

t = Time.now

begin
  # Running as an executable makes bundler irrelevant; from a gem means someone else decides about whether to use Bundler.
  unless RUNNING_FROM_EXECUTABLE or Gem.loaded_specs.has_key? APP_NAME
    require 'bundler'
    Bundler.setup :default
  end

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

require 'r18n-desktop'
R18n.from_env File.join(EXTRACT_PATH, 'config/lang'), Gosu.language

require 'chingu'
require_folder("chingu_ext", %w[basic_game_object])

require 'fidgit'
Fidgit::Element.schema.merge_schema! YAML.load(File.read(File.expand_path('config/gui/schema.yml', EXTRACT_PATH)))
require_folder("fidgit_ext", %w[element container cursor])

require 'texplay'
require_folder('texplay_ext', %w[color image window])
TexPlay.set_options(caching: false)

include Gosu
Font.factor_stored = 1
Font.factor_rendered = 1.0 / Font.factor_stored
include Chingu

SmashAndGrab::Log.log.debug { "Gems loaded in #{"%.3f" % (Time.now - t)} s" }

module SmashAndGrab
  t = Time.now

  # Setup Chingu's autoloading media directories.
  media_dir = File.expand_path('media', EXTRACT_PATH)
  Image.autoload_dirs.unshift File.join(media_dir, 'images')
  Sample.autoload_dirs.unshift File.join(media_dir, 'sounds')
  Song.autoload_dirs.unshift File.join(media_dir, 'music')
  Font.autoload_dirs.unshift File.join(media_dir, 'fonts')

  require_folder "std_ext", %w[array hash]

  # Include other files.
  require_folder("", %w[version sprite_sheet z_order z_order_recorder game_window mouse_selection combat_effects])
  require_folder("map", %w[tile wall map])
  require_folder("objects", %w[static entity vehicle])
  require_folder("gui", %w[minimap editor_selector entity_summary info_panel])
  require_folder("states", %w[edit_level play_level main_menu])
  require_folder("players", %w[ai human remote])
  require_folder("history", %w[editor_action_history game_action_history])

  Log.log.debug { "Scripts loaded in #{"%.3f" % (Time.now - t)} s" }

  FONT_NAME = "UnmaskedBB.ttf"
  module FontHeight
    SMALL = 12
    MEDIUM = 16
    LARGE = 20
  end

  t = Time.now
  GameWindow.new
  Log.log.debug { "Window created in #{"%.3f" % (Time.now - t)} s" }

  unless defined?(Ocra) or defined?(Bacon)
    Log.log.info { "Game window opened" }
    $window.show

    Log.log.info { "Game window closed" }
  end
end