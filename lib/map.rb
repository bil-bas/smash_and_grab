class Map
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

    @background = $window.record do
      @tiles.flatten.each(&:draw)
    end
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
  
  # Yields every tile visible to the view.
  def each_visible(view, &block)
=begin
    rect = view.rect
    
    min_y = [((rect.y - 16) / 8).floor, 0].max
    max_y = [((rect.y + rect.height) / 4.0).ceil, @tiles.size - 1].min
  
  visible_rows = @tiles[min_y..max_y]
  if visible_rows
    visible_rows.each do |row|
      #min_x = [((rect.x - 16) / tile_size).floor, 0].max
    #max_x = [((rect.x + rect.width) / 24).ceil, @tiles.first.size - 1].min
    tiles = row#[min_x..max_x]
    tiles.reverse_each {|tile| yield tile } if tiles
    end
  end
=end
   @tiles.each {|r| r.reverse_each {|t| yield t } }
  end
  
  # List of all objects visible in the view.
  def visible_objects(view)
    objects = []
    each_visible(view) {|tile| objects.push *tile.objects }
    objects
  end
  
  # Draws all tiles (only) visible in the window.
  def draw(offset_x, offset_y, zoom)
    @background.draw -offset_x, -offset_y, ZOrder::TILES, zoom, zoom
  end
end