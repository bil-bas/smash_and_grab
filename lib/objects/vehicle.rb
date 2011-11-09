require_relative "world_object"

class Vehicle < WorldObject
  CLASS = 'vehicle'

  CONFIG_MINIMAP_COLOR = 'minimap_color'
  CONFIG_SPRITESHEET_POSITION = 'spritesheet_position'

  attr_reader :minimap_color, :type

  def impassable?(person); true; end
  def passable?(person); false; end
  def inactive?; true; end

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def name; @type.split("_").map(&:capitalize).join(" "); end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/vehicles.yml", EXTRACT_PATH)); end
  def self.types; config.keys; end
  def self.sprites; @@sprites ||= SpriteSheet.new("vehicles.png", (96 * 2) + 2, (64 * 2) + 2, 4); end

  def initialize(map, data)
    @type = data[DATA_TYPE]
    config = self.class.config[@type]

    options = {
        image: self.class.sprites[*config[CONFIG_SPRITESHEET_POSITION]],
    }

    super(map, data, options)

    @minimap_color = Color.rgb(*config[CONFIG_MINIMAP_COLOR])

    raise @type unless @image
  end

  def draw
    # TODO: Draw as multiple fragments, so that zorder is correct.
    @image.draw_rot @x - 14, @y + 2.5 + 4, @y, 0, 0.5, 1, OUTLINE_SCALE * @factor_x, OUTLINE_SCALE
  end

  def to_json(*a)
    {
        DATA_CLASS => CLASS,
        DATA_TYPE => @type,
        DATA_ID => id,
        DATA_TILE => grid_position,
    }.to_json(*a)
  end
end