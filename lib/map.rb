require 'json'

class Map
  include Log

  class TileRow
    attr_reader :zorder

    def initialize(zorder)
      @zorder = zorder
      @tiles = []
    end

    def <<(tile)
      @tiles << tile
    end

    def draw(offset_x, offset_y, zoom)
      @recorded.draw -offset_x, -offset_y, @zorder, zoom, zoom
    end

    def record
      @recorded = $window.record do
        @tiles.each(&:draw)
      end
    end
  end

  DATA_SIZE = "size"
  DATA_TILES = "tiles"
  DATA_WALLS = "walls"
  DATA_ENTITIES = "entities"
  DATA_OBJECTS = "objects"

  attr_reader :grid_width, :grid_height
    
  def to_rect; Rect.new(0, 0, @grid_width * Tile::WIDTH, @grid_height * Tile::HEIGHT); end

  # tile_classes: Nested arrays of Tile class names (Tile::Grass is represented as "Grass")
  def initialize(data)
    t = Time.now

    tile_data = data[DATA_TILES]
    wall_data = data[DATA_WALLS]

    @objects = []
    @entities = []
    @static_objects = []
    @walls = []

    @grid_width, @grid_height = tile_data.size, tile_data[0].size
    @tiles = tile_data.map.with_index do |row, y|
      row.map.with_index do |tile_class, x|
        Tile.const_get(tile_class).new x, y
      end
    end

    # Fill the map with default walls (that is, no wall).
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        # Tile below.
        if y < @grid_height - 1
          Wall::None.new self, Wall::DATA_TILES => [[x, y], [x, y + 1]]
        end

        # Tile to right.
        if x < @grid_width - 1
          Wall::None.new self, Wall::DATA_TILES => [[x, y], [x + 1, y]]
        end
      end
    end

    wall_data.each do |wall_datum|
      Wall.const_get(wall_datum[Wall::DATA_TYPE]).new self, wall_datum
    end

    log.debug { "Map created in #{"%.3f" % (Time.now - t)} s" }

    record
  end

  def record
    @recorded_tiles = $window.record do
      @tiles.flatten.each(&:draw)
    end
  end

  def passable_tiles
    @tiles.flatten.select {|t| t.passable? nil }
  end
  
  def tile_at_position(x, y)
    x += Tile::WIDTH / 2
    tile_at_grid([[x / Tile::WIDTH - y / Tile::HEIGHT, 0].max, @grid_width - 1].min.floor,
                 [[x / Tile::WIDTH + y / Tile::HEIGHT, 0].max, @grid_height - 1].min.floor)
  end
  
  def tile_at_grid(x, y)
    if x >= 0 and x < @grid_width and y >= 0 and y < @grid_height
      @tiles[y][x]
    else
      nil
    end
  end
  
  # Draws all tiles (only) visible in the window.
  def draw_tiles(offset_x, offset_y, zoom)
    @recorded_tiles.draw -offset_x, -offset_y, ZOrder::TILES, zoom, zoom
  end

  def <<(object)
    case object
      when Character
        @entities << object
      when Wall
        @walls << object
    end

    @objects << object
  end

  def end_turn
    @entities.each(&:turn_reset)
  end

  def draw_objects
    @objects.each(&:draw)
  end

  def to_json(*a)
    # Get walls in two directions, since that will prevent duplicates.
    walls = @tiles.flatten.map {|t| [:left, :bottom].map {|d| t.wall(d) } }.flatten

    # Remove nils and default walls.
    walls = walls.compact.select {|w| not w.is_a? Wall::None }

    {
        DATA_SIZE => [@grid_width, @grid_height],
        DATA_TILES => @tiles,
        DATA_WALLS => walls,
        DATA_ENTITIES => @entities,
        DATA_OBJECTS => @static_objects,
    }.to_json(*a)
  end
end