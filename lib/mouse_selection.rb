class MouseSelection < GameObject
  attr_reader :selected_tile, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 60)
  MELEE_COLOR = Color.rgba(255, 0, 0, 80)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 30)
  ZOC_COLOR = Color.rgba(255, 0, 0, 255)

  def selected; @selected_tile ? @selected_tile.object : nil; end
  
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
        @path = @selected_tile.object.path_to(@hover_tile)
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
    @potential_moves = @selected_tile.object.potential_moves
    modify_occlusions @potential_moves, +1


    @moves_record = if @potential_moves.empty?
      nil
    else
      $window.record(1, 1) do
        @potential_moves.each do |tile|
          color = if entity = tile.object and entity.enemy?(@selected_tile.object)
            MELEE_COLOR
          else
            MOVE_COLOR
          end

          # Tile background
          Tile.blank.draw_rot tile.x, tile.y, 0, 0, 0.5, 0.5, 1, 1, color, :additive

          # ZOC indicator.
          if tile.entities_exerting_zoc(@selected_tile.object.faction).any?
            Tile.blank.draw_rot tile.x, tile.y, 0, 0, 0.5, 0.5, 0.2, 0.2, ZOC_COLOR
          end
        end
      end
    end
  end

  def modify_occlusions(tiles, amount)
    tiles.each do |tile|
      tile.modify_occlusions amount
    end
  end
  
  def draw
    # Draw a disc under the selected object.
    if @selected_tile
      selected_color = @selected_tile.object.move? ? Color::GREEN : Color::BLACK
      @selected_image.draw_rot @selected_tile.x, @selected_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, selected_color

      # Highlight all squares that character can travel to.
      @moves_record.draw 0, 0, ZOrder::TILE_SELECTION if @moves_record
      @path.draw if @path

    elsif @hover_tile
      color = (@hover_tile.empty? or @hover_tile.object.inactive?) ? Color::BLUE : Color::CYAN
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
            @map.actions.do :ability, selected.ability(:move).action_data(path)
            @selected_tile = @hover_tile
          when MeleePath
            attacker = selected
            @map.actions.do :ability, attacker.ability(:move).action_data(path.previous_path) if path.requires_movement?
            @map.actions.do :ability, attacker.ability(:melee).action_data(path.last)
            @selected_tile = attacker.tile
        end
        calculate_path
        calculate_potential_moves
      end
    elsif @hover_tile and @hover_tile.object.is_a? Entity and @hover_tile.object.active?
      # Select a character to move.
      select(@hover_tile.object)
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