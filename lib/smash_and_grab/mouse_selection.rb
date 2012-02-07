module SmashAndGrab
class MouseSelection < GameObject
  attr_reader :selected, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 60)
  MELEE_COLOR = Color.rgba(255, 0, 0, 80)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 30)
  ZOC_COLOR = Color.rgba(255, 0, 0, 100)
  
  def initialize(map, options = {})
    @map = map

    @potential_moves = []
    @potential_ranged = []

    @selected_image = Image["tile_selection.png"]
    @mouse_hover_image = Image["mouse_hover.png"]

    @selected = @hover_tile = nil
    @path = nil
    @moves_record = nil
    @ranged_record = nil
    @selected_changed_handler = nil

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)

    @map.factions.each do |faction|
      faction.subscribe :turn_ended do
        recalculate
      end
      faction.subscribe :turn_started do
        recalculate
      end
    end
  end

  def update
    self.selected = nil if selected and selected.tile.nil?

    # Ensure the character faces the mouse, but don't flip out when moving the mouse directly above or
    # below the character, so ensure that the cursor has to move a few pixels further across to trigger switch.
    if @hover_tile and selected_can_be_controlled?
      if (parent.cursor_world_x - selected.x >  2 and selected.factor_x < 0) or # Turn right
         (parent.cursor_world_x - selected.x < -2 and selected.factor_x > 0)    # Turn left
        selected.face parent.cursor_world_x
      end
    end

    super
  end

  def selected_can_be_controlled?
    selected and selected.active? and selected.faction.player.is_a?(Players::Human) and not @map.busy?
  end
  
  def tile=(tile)
    if tile != @hover_tile
      modify_occlusions @hover_tile, -1 if @hover_tile
      @hover_tile = tile
      modify_occlusions @hover_tile, +1 if @hover_tile
      calculate_path
    end
  end

  def calculate_path
    if selected_can_be_controlled?
      modify_occlusions @path.tiles, -1 if @path

      if @hover_tile
        @path = selected.path_to @hover_tile
        @path.prepare_for_drawing @potential_moves
        modify_occlusions @path.tiles, +1
      else
        @path = nil
      end
    else
      modify_occlusions @potential_moves, +1
      @potential_moves.clear
      modify_occlusions @potential_ranged, +1
      @potential_ranged.clear
    end
  end

  def calculate_potential_moves
    modify_occlusions @potential_moves, -1
    @potential_moves = selected.potential_moves
    modify_occlusions @potential_moves, +1

    @moves_record = if @potential_moves.empty?
      nil
    else
      $window.record(1, 1) do
        @potential_moves.each do |tile|
          entity = tile.object
          color = if entity and entity.enemy?(selected)
            MELEE_COLOR
          else
            MOVE_COLOR
          end

          # Tile background
          Tile.blank.draw_rot tile.x, tile.y, 0, 0, 0.5, 0.5, 1, 1, color, :additive

          # ZOC indicator.
          if tile.entities_exerting_zoc(selected.tile.object.faction).any? and tile.empty?
            Tile.blank.draw_rot tile.x, tile.y, 0, 0, 0.5, 0.5, 0.7, 0.7, ZOC_COLOR
          end
        end
      end
    end
  end

  def calculate_potential_ranged
    modify_occlusions @potential_ranged, -1
    @potential_ranged = selected.potential_ranged
    modify_occlusions @potential_ranged, +1

    # Draw a mark on all tiles that could be affected by ranged attack.
    @ranged_record = if @potential_ranged.empty?
      nil
    else
      $window.record 1, 1 do
        @potential_ranged.each do |tile|
          Tile.blank.draw_rot tile.x, tile.y, 0, 0, 0.5, 0.5, 0.3, 0.3, ZOC_COLOR
        end
      end
    end
  end

  def modify_occlusions(tiles, amount)
    Array(tiles).each do |tile|
      tile.modify_occlusions amount
    end
  end
  
  def draw
    # Draw a disc under the selected object.
    if selected and selected.tile
      selected_color = if selected.is_a? Objects::Entity
                         if selected_can_be_controlled? and selected.move?
                           Color::GREEN
                         else
                           Color::BLACK
                         end
                        else
                          Color::BLUE
                        end

      @selected_image.draw_rot selected.tile.x, selected.tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, selected_color

      # Highlight all squares that character can travel to.
      @moves_record.draw 0, 0, ZOrder::TILE_SELECTION if @moves_record
      @ranged_record.draw 0, 0, ZOrder::TILE_SELECTION if @ranged_record
      @path.draw if @path

    elsif @hover_tile
      color = (@hover_tile.empty? or @hover_tile.object.inactive?) ? Color::BLUE : Color::CYAN
      @mouse_hover_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color
    end

    # Make the stat-bars visible when hovering over something else.
    if @hover_tile
      object = @hover_tile.object
      object.draw_stat_bars 10000 if object.is_a? Objects::Entity and object.alive?
    end
  end

  def left_click
    if @potential_moves.include? @hover_tile
      path = @path # @path will change as we move.

      # Move the character, perhaps with melee at the end.
      case path
        when Paths::Move
          selected.use_ability :move, path
        when Paths::Melee
          selected.use_ability :move, path.previous_path if path.requires_movement?

          # Only perform melee if you weren't killed by attacks of opportunity.
          attacker, target = selected, path.last.object
          attacker.add_activity do
            attacker.use_ability :melee, target if attacker.alive?
          end
      end

      calculate_path
      calculate_potential_moves
      calculate_potential_ranged
    elsif @hover_tile and @hover_tile.object
      # Select a character to move.
      self.selected = @hover_tile.object
    end
  end

  def recalculate
    @moves_record = nil
    @ranged_record = nil

    if selected and selected_can_be_controlled?
      calculate_path
      calculate_potential_moves
      calculate_potential_ranged
    else
      modify_occlusions @potential_moves, -1
      @potential_moves.clear
      modify_occlusions @potential_ranged, -1
      @potential_ranged.clear

      modify_occlusions @path.tiles, -1 if @path
      @path = nil
    end
  end

  def selected=(object)
    # Make sure we learn of any changes made to the selected object so we can move.
    if selected
      @selected_changed_handler.unsubscribe
      @selected_changed_handler = nil
    end

    @selected = object
    recalculate

    if selected
      tile, path, potential_moves = selected.tile, @path, @potential_moves.dup

      @selected_changed_handler = selected.subscribe :changed do |entity|
        recalculate

        # Create a partial path while we move.
        if path and entity.tile != tile
          tile = entity.tile
          path.prepare_for_drawing potential_moves, from: entity.tile
          modify_occlusions path.tiles, +1
          @path = path
        end
      end
    end
  end

  def right_click
    self.selected = nil if selected
  end
end
end