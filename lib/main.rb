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
require 'chingu'
require 'fidgit'

require 'texplay'
require_folder('texplay_ext', %w[color image window])
TexPlay.set_options(caching: false)

include Gosu
include Chingu

# Setup Chingu's autoloading media directories.
media_dir = File.expand_path('media', EXTRACT_PATH)
Image.autoload_dirs.unshift File.join(media_dir, 'images')
Sample.autoload_dirs.unshift File.join(media_dir, 'sounds')
Song.autoload_dirs.unshift File.join(media_dir, 'music')
Font.autoload_dirs.unshift File.join(media_dir, 'fonts')

# Include other files.
require_folder("", %w[log version sprite_sheet z_order_recorder map minimap mouse_selection])
require_folder("tiles", %w[tile])
require_folder("objects", %w[static_object dynamic_object entity])
require_folder("walls", %w[wall])
require_folder("states", %w[world])


class ZOrder
  BACKGROUND = -Float::INFINITY
  TILES = -99999
  TILE_SELECTION = -99998
  # Objects -1000 .. +1000

  GUI = Float::INFINITY
end


class GameWindow < Chingu::Window
  attr_reader :pixel

  def setup
    enable_undocumented_retrofication

    @pixel = Image.create 1, 1
    @pixel.clear color: :white

    self.caption = "Smash and Grab - By Spooner [Escape - reset turn; F5/F6 - quicksave/load; Ctrl-z/y - undo/redo]"

    self.cursor = true
    push_game_state World
  end
end

Log.log.debug { "Scripts loaded in #{"%.3f" % (Time.now - t)} s" }

GameWindow.new.show unless defined? Ocra
