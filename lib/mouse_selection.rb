class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 50)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 25)
  
  def initialize(options = {})
    @potential_moves = []

    @selected_image = Image["tile_selection.png"]
    @partial_move_image = Image["partial_move.png"]
    @final_move_image = Image["final_move.png"]
    @partial_move_too_far_image = Image["partial_move_too_far.png"]
    @final_move_too_far_image = Image["final_move_too_far.png"]

    @selected_tile = @hover_tile = nil
    @path = nil
    @path_record = @moves_record = nil

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)
  end
  
  def tile=(tile)
    @hover_tile = tile
  end

  def update
    super

    if @selected_tile
      if @hover_tile != @selected_tile and (@path.nil? or @hover_tile != @path.current)
        @path = @selected_tile.objects.last.path_to(@hover_tile)
        @path_record = nil
      end
    else
      @potential_moves.clear
    end
  end

  def calculate_potential_moves
    @potential_moves = @selected_tile.objects[0].potential_moves
  end
  
  def draw(offset_x, offset_y, zoom)
    # Draw a disc under the selected object.
    if @selected_tile
      selected_color = Color::GREEN # Assume everyone is a friend for now.
      @selected_image.draw_rot @selected_tile.x, @selected_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, selected_color

      # Highlight all squares that character can travel to.
      unless @potential_moves.empty?
        @moves_record ||= $window.record do
          @potential_moves.each do |tile|
            Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, MOVE_COLOR, :additive
          end
        end

        @moves_record.draw -offset_x, -offset_y, ZOrder::TILE_SELECTION, zoom, zoom, Color::WHITE, :additive
      end

      # Show path and end of the move-path chosen.
      if @hover_tile and @hover_tile != @selected_tile
        @path_record ||= $window.record do
          tiles = @path.nil? ? [@selected_tile, @hover_tile] : @path.tiles
          tiles[1..-1].each do |tile|
            can_move = @potential_moves.include? tile

            image = if tile == tiles.last
              if tile.empty?
                can_move ? @final_move_image : @final_move_too_far_image
              else
                @final_move_too_far_image
              end
            else
              can_move ? @partial_move_image : @partial_move_too_far_image
            end

            image.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color
          end
        end

        @path_record.draw -offset_x, -offset_y, ZOrder::TILE_SELECTION, zoom, zoom
      end
    end
  end

  def left_click
    if @selected_tile
      # Move the character.
      if @potential_moves.include? @hover_tile and @hover_tile.empty?
        character = @selected_tile.objects.last
        character.move_to @hover_tile
        @path = nil
        @moves_record = nil
        @selected_tile = @hover_tile
        calculate_potential_moves
      end
    elsif @hover_tile and @hover_tile.objects.any?
      # Select a character to move.
      @selected_tile = @hover_tile
      @moves_record = nil
      @potential_moves = @selected_tile.objects[0].potential_moves
    end
  end

  def right_click
    # Deselect the currently selected character.
    if @selected_tile
      @potential_moves.clear
      @path = nil
      @selected_tile = nil
    end
  end
end