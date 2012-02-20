require_relative "world_object"

module SmashAndGrab
module Objects
# A vehicle is a 4x2 tile object.
class Vehicle < WorldObject
  CLASS = :vehicle

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

  class << self
    def config; @config ||= YAML.load_file(File.expand_path("config/map/vehicles.yml", EXTRACT_PATH)); end
    def types; config.keys; end
    def sprites; @sprites ||= SpriteSheet["vehicles.png", (128 * 2) + 2, (128 * 2) + 2, 3]; end
  end

  def fills_tile_on_minimap?; true; end

  def initialize(map, data)
    @type = data[:type]
    config = self.class.config[@type]

    options = {
        image: self.class.sprites[*config[:spritesheet_position]],
    }

    # Add the vehicle to all other tiles it is standing on top of.
    @shape = config[:shape]

    super(map, data, options)

    @center_x, @center_y = 0.5, 1

    @minimap_color = Color.rgb(*config[:minimap_color])

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

  def draw_base
    tiles do |tile|
      Image["tiles_selection.png"].draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, base_color
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
end
end
end