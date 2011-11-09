require_relative "world_object"

# A vehicle is a 4x2 tile object.
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

    @center_x, @center_y = 2.0 / 3.0, 1

    @minimap_color = Color.rgb(*config[CONFIG_MINIMAP_COLOR])

    raise @type unless @image
  end

  def draw
    # Draw the image in sections, since it has to exist at several zorder positions in order to render correctly.
    [
        [32, 0],
        [64, -8],
        [96, -16],
        [128, -24],
    ].each do |clip_width, offset_z|
      $window.clip_to @x - clip_width / 2, -10000, clip_width, 20000 do
        @image.draw_rot @x, @y + 2.5, @y + offset_z, 0, @center_x, @center_y, OUTLINE_SCALE * @factor_x, OUTLINE_SCALE
      end
    end
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