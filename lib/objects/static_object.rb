require_relative "world_object"

class StaticObject < WorldObject
  CLASS = 'object'

  CONFIG_PASSABLE = 'passable'
  CONFIG_MINIMAP_COLOR = 'minimap_color'
  CONFIG_SPRITESHEET_POSITION = 'spritesheet_position'

  attr_reader :minimap_color, :type

  def impassable?(person); !@passable; end
  def passable?(person); @passable; end
  def inactive?; true; end

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def name; @type.split("_").map(&:capitalize).join(" "); end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/objects.yml", EXTRACT_PATH)); end
  def self.types; config.keys; end
  def self.sprites; @@sprites ||= SpriteSheet.new("objects.png", 64 + 2, 64 + 2, 8); end

  def initialize(map, data)
    @type = data[DATA_TYPE]
    config = self.class.config[data[DATA_TYPE]]

    options = {
        image: self.class.sprites[*config[CONFIG_SPRITESHEET_POSITION]],
    }

    super(map, data, options)

    @minimap_color = Color.rgb(*config[CONFIG_MINIMAP_COLOR])
    @passable = config[CONFIG_PASSABLE]

    raise @type unless @image
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