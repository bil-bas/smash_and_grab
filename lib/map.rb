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

  attr_reader :grid_width, :grid_height
    
  def to_rect; Rect.new(0, 0, @grid_width * Tile::WIDTH, @grid_height * Tile::HEIGHT); end

  # tile_classes: Nested arrays of Tile class names (Tile::Grass is represented as "Grass")
  def initialize(tile_classes)
    t = Time.now

    @objects = []
    @entities = []
    @static_objects = []
    @walls = []

    @grid_width, @grid_height = tile_classes.size, tile_classes[0].size
    @tiles = tile_classes.map.with_index do |row, y|
      row.map.with_index do |tile_class, x|
        Tile.const_get(tile_class).new x, y
      end
    end

    # Fill the map with default walls (that is, no wall).
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        # Tile below.
        if y < @grid_height - 1
          Wall::None.new self, tile, tile_at_grid(x, y + 1)
        end

        # Tile to right.
        if x < @grid_width - 1
          Wall::None.new self, tile, tile_at_grid(x + 1, y)
        end
      end
    end

    # Back wall.
    Wall::HighConcreteWall.new self, tile_at_grid(1, 2), tile_at_grid(1, 3)
    Wall::HighConcreteWallWindow.new self, tile_at_grid(2, 2), tile_at_grid(2, 3)
    Wall::HighConcreteWallWindow.new self, tile_at_grid(3, 2), tile_at_grid(3, 3)
    Wall::HighConcreteWall.new self, tile_at_grid(4, 2), tile_at_grid(4, 3)

    # Left wall
    Wall::HighConcreteWall.new self, tile_at_grid(0, 3), tile_at_grid(1, 3)
    #Wall::HighConcreteWall.new self, tile_at_grid(0, 4), tile_at_grid(1, 4)
    Wall::HighConcreteWall.new self, tile_at_grid(0, 5), tile_at_grid(1, 5)
    Wall::HighConcreteWall.new self, tile_at_grid(0, 6), tile_at_grid(1, 6)

    # Front wall.
    Wall::HighConcreteWall.new self, tile_at_grid(1, 6), tile_at_grid(1, 7)
    Wall::HighConcreteWallWindow.new self, tile_at_grid(2, 6), tile_at_grid(2, 7)
    Wall::HighConcreteWallWindow.new self, tile_at_grid(3, 6), tile_at_grid(3, 7)
    Wall::HighConcreteWall.new self, tile_at_grid(4, 6), tile_at_grid(4, 7)

    # Right wall
    Wall::HighConcreteWall.new self, tile_at_grid(4, 3), tile_at_grid(5, 3)
    Wall::HighConcreteWall.new self, tile_at_grid(4, 4), tile_at_grid(5, 4)
    Wall::HighConcreteWall.new self, tile_at_grid(4, 5), tile_at_grid(5, 5)
    Wall::HighConcreteWall.new self, tile_at_grid(4, 6), tile_at_grid(5, 6)

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
        size: [@grid_width, @grid_height],
        tiles: @tiles,
        walls: walls,
        entities: @entities,
        objects: @static_objects,
    }.to_json(*a)
  end
end