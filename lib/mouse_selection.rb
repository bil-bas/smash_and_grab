class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 25)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 25)
  
  def initialize(options = {})
    @potential_moves = []

    @selected_image = Image["tile_selection.png"]
    @partial_move_image = Image["partial_move.png"]
    @final_move_image = Image["final_move.png"]

    @selected_tile = @hover_tile = nil

    @path = []

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

    @path.clear

    if @selected_tile
      @potential_moves = @selected_tile.objects[0].potential_moves if @potential_moves.empty?

      if @hover_tile != @selected_tile and @potential_moves.include? @hover_tile
        @path = @selected_tile.objects.last.path_to(@hover_tile)
        @path.shift # Remove the starting square.
        @path.pop # Remove the last square.
      end
    elsif @hover_tile and @hover_tile.objects.any?
      @potential_moves = @hover_tile.objects[0].potential_moves if @potential_moves.empty?
    else
      @potential_moves.clear
    end
  end
  
  def draw
    # Draw a disc under the selected object.
    if @selected_tile
      selected_color = Color::GREEN # Assume everyone is a friend for now.
      @selected_tile.draw_isometric_image @selected_image, ZOrder::TILE_SELECTION, color: selected_color

      # Highlight all pixels that character can travel to.
      pixel = $window.pixel
      @potential_moves.each do |tile|
        tile.draw_isometric_image pixel, ZOrder::TILE_SELECTION, color: MOVE_COLOR, mode: :additive
      end

      # Show path and end of the move-path chosen.
      if @potential_moves.include? @hover_tile
        @path.each do |tile|
          tile.draw_isometric_image @partial_move_image, ZOrder::TILE_SELECTION
        end

        @hover_tile.draw_isometric_image @final_move_image, ZOrder::TILE_SELECTION
      end
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