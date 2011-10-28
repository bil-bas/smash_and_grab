class Minimap < GameObject
  def initialize(map, options = {})
    options = {
        factor: 2,
        x: 80,
        y: 100,
        angle: -45,
        rotation_center: :center_center
    }.merge! options

    @map = map

    super options

    self.image = Image.create @map.grid_width, @map.grid_height

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
    self.image.set_pixel tile.grid_x, tile.grid_y, color: tile.minimap_color

    tile
  end
end
