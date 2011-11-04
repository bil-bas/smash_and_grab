class Minimap < GameObject
  TILE_WIDTH = 3
  MARGIN = TILE_WIDTH * 2
  MARGIN_COLOR = Color.rgba(50, 50, 50, 200)

  attr_accessor :map

  def initialize(map, options = {})
    options = {
        x: $window.width - 10,
        y: 10,
        rotation_center: :top_right,
        zorder: ZOrder::GUI,
    }.merge! options

    @map = map

    super options

    @image = Image.create @map.grid_width * TILE_WIDTH + MARGIN * 2, @map.grid_height * TILE_WIDTH + MARGIN * 2
    @image.clear color: MARGIN_COLOR

    refresh
  end

  # Refresh the whole minimap/
  def refresh
    @map.grid_width.times do |x|
      @map.grid_height.times do |y|
        update_tile(@map.tile_at_grid(x, y))
      end
    end
  end

  def update_tile(tile)
    x, y = tile.grid_x * TILE_WIDTH + MARGIN, tile.grid_y * TILE_WIDTH + MARGIN

    # Draw the tile
    @image.rect x, y, x + TILE_WIDTH - 1, y + TILE_WIDTH - 1, color: tile.minimap_color, fill: true

    # Draw the two walls.
    if wall = tile.wall(:up) and wall.minimap_color != Color::NONE
      @image.line x, y + TILE_WIDTH - 4, x + TILE_WIDTH, y + TILE_WIDTH - 4, color: wall.minimap_color
    end

    if wall = tile.wall(:left) and wall.minimap_color != Color::NONE
      @image.line x, y, x, y + TILE_WIDTH, color: wall.minimap_color
    end

    # Draw the tile object.
    unless tile.empty?
      @image.rect x + 1, y, x + TILE_WIDTH - 1, y + TILE_WIDTH - 2, color: tile.objects.last.minimap_color, fill: true
    end

    tile
  end
end
