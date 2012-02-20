NUM_DAMAGE_TYPES = 9
DICE_BACKGROUND = 0
ELEMENT_BACKGROUND = 2
RESISTANCE_BACKGROUND = 1
VULNERABILITY_BACKGROUND = 3
SPRITE_WIDTH, SPRITE_HEIGHT = 16, 16

desc "Process images (cut out a portrait of each character)"
task :create_dice do
  require 'texplay'
  require_relative '../lib/smash_and_grab/texplay_ext/color'
  require_relative '../lib/smash_and_grab/texplay_ext/image'
  require_relative '../lib/smash_and_grab/texplay_ext/window'

  puts "=== Creating dice ===\n\n"

  $window = Gosu::Window.new(100, 100, false)

  puts "Making dice"

  sprites = Gosu::Image.load_tiles($window, "raw_media/images/dice.png", SPRITE_WIDTH, SPRITE_HEIGHT, false)
  sprites.each(&:refresh_cache)

  backgrounds = sprites[(NUM_DAMAGE_TYPES * 2)..-1]
  create_icons "elements", sprites[0, NUM_DAMAGE_TYPES], backgrounds[ELEMENT_BACKGROUND]
  create_icons "dice0", sprites[0, NUM_DAMAGE_TYPES], backgrounds[DICE_BACKGROUND], 0.3
  create_icons "dice1", sprites[0, NUM_DAMAGE_TYPES], backgrounds[DICE_BACKGROUND]
  create_icons "dice2", sprites[NUM_DAMAGE_TYPES, NUM_DAMAGE_TYPES], backgrounds[ DICE_BACKGROUND]
  create_icons "resistances", sprites[0, NUM_DAMAGE_TYPES], backgrounds[RESISTANCE_BACKGROUND]
  create_icons "vulnerabilities", sprites[0, NUM_DAMAGE_TYPES], backgrounds[VULNERABILITY_BACKGROUND]
end

def create_icons(name, sprites, background, alpha = 1.0)
  @config ||= YAML.load_file "config/map/combat_dice.yml"

  new_image = Gosu::Image.create SPRITE_WIDTH * NUM_DAMAGE_TYPES, SPRITE_HEIGHT, color: [0, 0, 0, 0]
  new_image.refresh_cache

  print "  Splicing #{name}:   "
  sprites.each.with_index do |sprite, i|
    config = @config.values.find {|c| c[:spritesheet_column] == i }
    if background
      new_image.splice background, i * SPRITE_WIDTH, 0, color_control: lambda { |dest, source|
        if source == [1, 1, 1, 1]
          Gosu::Color.rgb *config[:color]
        else
          dest
        end
      }
    end
    new_image.splice sprite, i * SPRITE_WIDTH, 0, alpha_blend: true, color_control: lambda { |dest, source|
      if source[3] > 0
        source[3] *= alpha
        source
      else
        dest
      end
    }
    print '.'
  end

  puts "\n"

  new_image.save(File.expand_path("media/images/#{name}.png"))
end