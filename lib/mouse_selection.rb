class MouseSelection < GameObject
  attr_reader :tile
  
  def initialize(options = {})
    options = {
        image: Image["tile_selection.png"],
    }.merge! options
    
    super(options)
  end
  
  def tile=(tile)
    @tile = tile
  end
  
  def draw
    @image.draw_rot @tile.x, @tile.y, ZOrder::TILE_SELECTION, 0 if @tile
  end
end