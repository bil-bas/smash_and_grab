class Minimap < Fidgit::Vertical
  TILE_WIDTH = 3
  BACKGROUND_COLOR = Color::BLACK
  MARGIN = TILE_WIDTH * 2
  MARGIN_COLOR = Color.rgba(0, 0, 0, 255)

  attr_reader :map

  def initialize(options = {})
    options = {
        background_color: BACKGROUND_COLOR,
        padding: 4,
    }.merge! options

    @map = nil

    super options

    vertical padding: MARGIN, background_color: MARGIN_COLOR do
      @map_frame = image_frame nil, padding: 0
    end
  end

  def hit_element(x, y)
    hit?(x, y) ? self : nil
  end

  public
  def map=(map)
    @map = map

    image = Image.create @map.grid_width * TILE_WIDTH, @map.grid_height * TILE_WIDTH
    image.refresh_cache
    image.clear color: :alpha
    @map_frame.image = image
    recalc

    update_whole_map
    self.x = ($window.width) - width

    map
  end


  # Refresh the whole minimap/
  protected
  def update_whole_map
    @map.grid_width.times do |x|
      @map.grid_height.times do |y|
        update_tile(@map.tile_at_grid(x, y))
      end
    end

    self
  end

  public
  def update_tile(tile)
    image = @map_frame.image

    x, y = tile.grid_x * TILE_WIDTH, tile.grid_y * TILE_WIDTH

    # Draw the tile
    image.rect x, y, x + TILE_WIDTH - 1, y + TILE_WIDTH - 1, color: tile.minimap_color, fill: true

    # Draw the two walls.
    if wall = tile.wall(:up) and wall.minimap_color != Color::NONE
      image.line x, y + TILE_WIDTH - 4, x + TILE_WIDTH, y + TILE_WIDTH - 4, color: wall.minimap_color
    end

    if wall = tile.wall(:left) and wall.minimap_color != Color::NONE
      image.line x, y, x, y + TILE_WIDTH, color: wall.minimap_color
    end

    # Draw the tile object.
    unless tile.empty?
      x, y, width, height = if tile.object.fills_tile_on_minimap?
        [x, y, TILE_WIDTH - 1, TILE_WIDTH - 1]
      else
        [x + 1, y, TILE_WIDTH - 2, TILE_WIDTH - 2]
      end

      image.rect x, y, x + width, y + height, color: tile.object.minimap_color, fill: true
    end

    tile
  end
end
