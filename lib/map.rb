class Map
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

  def initialize(grid_width, grid_height)
    @grid_width, @grid_height = grid_width, grid_height
    @tiles = Array.new(@grid_height) { Array.new(@grid_width) }
  
    possible_tiles = [
        *([Tile::Concrete] * 5),
        *([Tile::Grass] * 1),
    ]

    @grid_height.times do |y|
      @grid_width.times do |x|
        @tiles[y][x] = possible_tiles.sample.new x, y
      end
    end

    # Generate a random maze of walls.
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        # Tile below.
        if y < @grid_height - 1
          if rand() < 0.1
            [Wall::HighConcreteWallWindow, Wall::HighConcreteWall].sample.new tile, tile_at_grid(x, y + 1)
          else
            Wall::None.new tile, tile_at_grid(x, y + 1)
          end
        end

        # Tile to right.
        if x < @grid_width - 1
          if rand() < 0.1
            [Wall::HighConcreteWallWindow, Wall::HighConcreteWall].sample.new tile, tile_at_grid(x + 1, y)
          else
            Wall::None.new tile, tile_at_grid(x + 1, y)
          end
        end
      end
    end

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
  def draw(offset_x, offset_y, zoom)
    @recorded_tiles.draw -offset_x, -offset_y, ZOrder::TILES, zoom, zoom
  end
end