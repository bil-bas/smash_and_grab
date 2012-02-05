require_relative "world_object"

module SmashAndGrab
module Objects
class Static < WorldObject
  CLASS = :object

  attr_reader :minimap_color, :type

  def impassable?(person); !@passable; end
  def passable?(person); @passable; end
  def inactive?; true; end

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def name; @type.to_s.split("_").map(&:capitalize).join(" "); end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/objects.yml", EXTRACT_PATH)); end
  def self.types; config.keys; end
  def self.sprites; @@sprites ||= SpriteSheet.new("objects.png", 64 + 2, 64 + 2, 8); end

  def initialize(map, data)
    @type = data[:type]
    config = self.class.config[@type]

    options = {
        image: self.class.sprites[*config[:spritesheet_position]],
    }

    super(map, data, options)

    @minimap_color = Color.rgb(*config[:minimap_color])
    @passable = config[:passable]

    raise @type unless @image
  end

  def to_json(*a)
    {
        class: CLASS,
        type: @type,
        id: id,
        tile: grid_position,
    }.to_json(*a)
  end
end
end
end