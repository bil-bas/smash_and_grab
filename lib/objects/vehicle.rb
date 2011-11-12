require_relative "world_object"

# A vehicle is a 4x2 tile object.
class Vehicle < WorldObject
  CLASS = 'vehicle'

  CONFIG_MINIMAP_COLOR = 'minimap_color'
  CONFIG_SPRITESHEET_POSITION = 'spritesheet_position'
  CONFIG_SHAPE = 'shape'

  # [Width of draw clip, z-order offset]
  DRAW_POSITIONS = [
        [Tile::WIDTH * 1,  0],
        [Tile::WIDTH * 2, -Tile::HEIGHT / 2],
        [Tile::WIDTH * 3, -Tile::HEIGHT],
        [Tile::WIDTH * 4, -(Tile::HEIGHT * 1.5).to_i],
  ]

  attr_reader :minimap_color, :type

  def impassable?(person); true; end
  def passable?(person); false; end
  def inactive?; true; end

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def name; @type.split("_").map(&:capitalize).join(" "); end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/vehicles.yml", EXTRACT_PATH)); end
  def self.types; config.keys; end
  def self.sprites; @@sprites ||= SpriteSheet.new("vehicles.png", (128 * 2) + 2, (128 * 2) + 2, 3); end

  def fills_tile_on_minimap?; true; end

  def initialize(map, data)
    @type = data[DATA_TYPE]
    config = self.class.config[@type]

    options = {
        image: self.class.sprites[*config[CONFIG_SPRITESHEET_POSITION]],
    }

    # Add the vehicle to all other tiles it is standing on top of.
    @shape = config[CONFIG_SHAPE]

    super(map, data, options)

    @center_x, @center_y = 0.5, 1

    @minimap_color = Color.rgb(*config[CONFIG_MINIMAP_COLOR])

    raise @type unless @image
  end

  def tile=(tile)
    if @tile
      tiles do |secondary_tile|
        secondary_tile.remove self
      end
    end

    @tile = tile
    self.x, self.y = tile.x, tile.y if @tile

    if @tile
      tiles do |secondary_tile|
        secondary_tile << self
      end
    end
  end

  # Iterates through the tiles that the object sits on.
  def tiles(&block)
    x, y = grid_x, grid_y
    @shape[0].times do |offset_x|
      @shape[1].times do |offset_y|
        # TODO: Alter tiles based on facing.
        tile = @map.tile_at_grid(x + offset_x, y - offset_y)
        yield tile if tile
      end
    end
  end

  def draw
    # Draw the image in sections, since it has to exist at several zorder positions in order to render correctly.
    DRAW_POSITIONS.each do |clip_width, offset_z|
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