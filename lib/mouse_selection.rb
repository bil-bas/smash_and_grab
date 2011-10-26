class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 25)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 25)
  
  def initialize(options = {})
    options = {
        image: Image["tile_selection.png"],
    }.merge! options

    @potential_moves = []

    @selected_tile = @hover_tile = nil

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)
  end
  
  def tile=(tile)
    @potential_moves.clear if tile != @hover_tile
    @hover_tile = tile
  end

  def update
    super

    if @selected_tile
      @potential_moves = @selected_tile.objects[0].potential_moves if @potential_moves.empty?
    elsif @hover_tile and @hover_tile.objects.any?
      @potential_moves = @hover_tile.objects[0].potential_moves if @potential_moves.empty?
    else
      @potential_moves.clear
    end
  end
  
  def draw
    @image.draw_rot @selected_tile.x, @selected_tile.y - 0.5, ZOrder::TILE_SELECTION, 0 if @selected_tile

    pixel = $window.pixel
    @potential_moves.each do |tile|
      pixel.draw_as_quad tile.x - Tile::WIDTH / 2, tile.y,  MOVE_COLOR, # Left
                    tile.x, tile.y - Tile::HEIGHT / 2, MOVE_COLOR, # Top
                    tile.x + Tile::WIDTH / 2, tile.y,  MOVE_COLOR, # Right
                    tile.x, tile.y + Tile::HEIGHT / 2, MOVE_COLOR, # Bottom
                    ZOrder::TILE_SELECTION, :additive
    end
  end

  def left_click
    if @hover_tile and @hover_tile.objects.any?
      # Select a character to move.
      unless @selected_tile
        @selected_tile = @hover_tile
        @potential_moves.clear
      end
    elsif @selected_tile
      # Move the character.
      if @potential_moves.include? @hover_tile
        character = @selected_tile.objects.last
        character.move_to @hover_tile
        @potential_moves.clear
        @selected_tile = @hover_tile
      end
    end
  end

  def right_click
    # Deselect the currently selected character.
    @potential_moves.clear
    @selected_tile = nil
  end
end