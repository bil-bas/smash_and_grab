class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 50)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 25)
  
  def initialize(map, options = {})
    @map = map

    @potential_moves = []

    @selected_image = Image["tile_selection.png"]
    @partial_move_image = Image["partial_move.png"]
    @final_move_image = Image["final_move.png"]
    @partial_move_too_far_image = Image["partial_move_too_far.png"]
    @final_move_too_far_image = Image["final_move_too_far.png"]
    @mouse_hover_image = Image["mouse_hover.png"]

    @selected_tile = @hover_tile = nil
    @path = nil
    @path_record = @moves_record = nil

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)
  end
  
  def tile=(tile)
    if tile != @hover_tile
      modify_occlusions [@hover_tile], -1 if @hover_tile
      @hover_tile = tile
      modify_occlusions [@hover_tile], +1 if @hover_tile
    end
  end

  def update
    super

    if @selected_tile
      if @hover_tile != @selected_tile and (@path.nil? or @hover_tile != @path.current)
        modify_occlusions @path.tiles, -1 if @path
        @path = @selected_tile.objects.last.path_to(@hover_tile)

        modify_occlusions @path.tiles, +1 if @path

        @path_record = nil
      end
    else
      modify_occlusions @potential_moves, +1
      @potential_moves.clear
    end
  end

  def calculate_potential_moves
    modify_occlusions @potential_moves, -1
    @potential_moves = @selected_tile.objects.last.potential_moves
    modify_occlusions @potential_moves, +1
  end

  def modify_occlusions(tiles, amount)
    tiles.each do |tile|
      tile.modify_occlusions amount
    end
  end
  
  def draw(offset_x, offset_y, zoom)
    # Draw a disc under the selected object.
    if @selected_tile
      selected_color = @selected_tile.objects.last.move? ? Color::GREEN : Color::BLACK
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
              if tile.objects.last.is_a? Entity
                @final_move_too_far_image
              else
                can_move ? @final_move_image : @final_move_too_far_image
              end
            else
              can_move ? @partial_move_image : @partial_move_too_far_image
            end

            image.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color
          end
        end

        @path_record.draw -offset_x, -offset_y, ZOrder::TILE_SELECTION, zoom, zoom
      end
    elsif @hover_tile
      color = @hover_tile.empty? ? Color::BLUE : Color::CYAN
      @mouse_hover_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color
    end
  end

  def left_click
    if @selected_tile
      # Move the character.
      if @potential_moves.include? @hover_tile and @hover_tile.end_turn_on?(@selected_tile.objects.last)
        character = @selected_tile.objects.last
        @map.actions.do :move, @path

        modify_occlusions @path.tiles, -1 if @path
        @path = nil

        @moves_record = nil
        @selected_tile = @hover_tile
        calculate_potential_moves
      end
    elsif @hover_tile and @hover_tile.objects.last.is_a? Entity
      # Select a character to move.
      select(@hover_tile.objects.last)
    end
  end

  def select(entity)
    if entity
      @selected_tile = entity.tile
      @moves_record = nil
      calculate_potential_moves
    else
      modify_occlusions @potential_moves, -1
      @potential_moves.clear

      modify_occlusions @path.tiles, -1 if @path
      @path = nil

      @selected_tile = nil
    end
  end

  def right_click
    # Deselect the currently selected character.
    if @selected_tile
      select nil
    end
  end

  def turn_reset
    if @selected_tile
      current_tile = @selected_tile
      right_click
      @selected_tile = current_tile
      @moves_record = nil
      calculate_potential_moves
      @map.actions.do :end_turn
    end
  end
end