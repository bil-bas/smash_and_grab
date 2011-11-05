class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 90)
  MELEE_COLOR = Color.rgba(255, 0, 0, 120)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 25)

  def selected; @selected_tile ? @selected_tile.entity : nil; end
  
  def initialize(map, options = {})
    @map = map

    @potential_moves = []

    @selected_image = Image["tile_selection.png"]
    @mouse_hover_image = Image["mouse_hover.png"]

    @selected_tile = @hover_tile = nil
    @path = nil
    @moves_record = nil

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)
  end
  
  def tile=(tile)
    if tile != @hover_tile
      modify_occlusions [@hover_tile], -1 if @hover_tile
      @hover_tile = tile
      modify_occlusions [@hover_tile], +1 if @hover_tile
      calculate_path
    end
  end

  def calculate_path
    if @selected_tile
      modify_occlusions @path.tiles, -1 if @path

      if @hover_tile
        @path = @selected_tile.entity.path_to(@hover_tile)
        @path.prepare_for_drawing(@potential_moves)
        modify_occlusions @path.tiles, +1
      else
        @path = nil
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
    @moves_record = nil
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
            color = if entity = tile.objects.last and entity.enemy?(@selected_tile.objects.last)
              MELEE_COLOR
            else
              MOVE_COLOR
            end
            # TODO: Additive doesn't work in Gosu recordings :(
            Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color, :additive
          end
        end

        @moves_record.draw -offset_x, -offset_y, ZOrder::TILE_SELECTION, zoom, zoom
      end

      @path.draw -offset_x, -offset_y, zoom  if @path

    elsif @hover_tile
      color = (@hover_tile.empty? or @hover_tile.entity.inactive?) ? Color::BLUE : Color::CYAN
      @mouse_hover_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color
    end
  end

  def left_click
    if @selected_tile
      path = @path
      # Move the character.
      if @potential_moves.include? @hover_tile
        case path
          when MovePath
            @map.actions.do :move, path
            @selected_tile = @hover_tile
          when MeleePath
            @map.actions.do :move, path.previous_path if path.requires_movement?
            @map.actions.do :melee, path
            @selected_tile = path.attacker.tile
        end
        calculate_path
        calculate_potential_moves
      end
    elsif @hover_tile and @hover_tile.entity.is_a? Entity and @hover_tile.entity.active?
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
end