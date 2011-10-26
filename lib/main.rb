EXTRACT_PATH = File.expand_path('../..', __FILE__)

def require_folder(path, files)
  files.each do |file|
    if path.empty?
      require_relative file
    else
      require_relative File.join(path, file)
    end
  end
end

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

require 'gosu'
require 'chingu'
require 'fidgit'
require 'texplay'
require_folder('texplay_ext', %w[color image window])

include Gosu
include Chingu

# Setup Chingu's autoloading media directories.
media_dir = File.expand_path('media', EXTRACT_PATH)
Image.autoload_dirs.unshift File.join(media_dir, 'images')
Sample.autoload_dirs.unshift File.join(media_dir, 'sounds')
Song.autoload_dirs.unshift File.join(media_dir, 'music')
Font.autoload_dirs.unshift File.join(media_dir, 'fonts')

# Include other files.
require_folder("", %w[map mouse_selection])
require_folder("objects", %w[static_object dynamic_object])
require_folder("tiles", %w[tile])
require_folder("states", %w[world])

class ZOrder
  BACKGROUND = -Float::INFINITY
  TILES = -99999
  TILE_SELECTION = -99998
  # Objects -1000 .. +1000

  GUI = Float::INFINITY
end

class Tree < StaticObject
  def initialize(grid_position, options = {})
    unless defined? @@sprites
      @@sprites = Image.load_tiles($window, File.expand_path("media/images/characters.png", EXTRACT_PATH), 32, 32, true)
    end

    options = {
        image: @@sprites.sample,
        factor_x: [-1, 1].sample,
    }.merge! options
     
    super(grid_position, options)
  end  
end

class GameWindow < Chingu::Window
  def setup
    enable_undocumented_retrofication
    self.cursor = true
    push_game_state World
  end
end

GameWindow.new.show
