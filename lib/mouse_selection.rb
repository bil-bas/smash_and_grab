class MouseSelection < GameObject
  attr_reader :tile
  
  def initialize(options = {})
    options = {
        image: Image["tile_selection.png"],
    }.merge! options

    @potential_move_image = Image["potential_move.png"]
    @potential_moves = []
    
    super(options)
  end
  
  def tile=(tile)
    @tile = tile
  end

  def update
    if @tile and @tile.objects.any?
      @potential_moves = @tile.objects[0].potential_moves
    else
      @potential_moves = []
    end
  end
  
  def draw
    @image.draw_rot @tile.x, @tile.y - 0.5, ZOrder::TILE_SELECTION, 0 if @tile

    @potential_moves.each do |tile|
      @potential_move_image.draw_rot tile.x, tile.y - 0.5, ZOrder::TILE_SELECTION, 0
    end
  end
end