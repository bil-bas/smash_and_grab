module SmashAndGrab
class MouseSelection < GameObject
  attr_reader :selected, :hover_tile

  MOVE_COLOR = Color.rgba(0, 255, 0, 60)
  MELEE_COLOR = Color.rgba(255, 0, 0, 80)
  NO_MOVE_COLOR = Color.rgba(255, 0, 0, 30)
  ZOC_COLOR = Color.rgba(255, 0, 0, 255)
  
  def initialize(map, options = {})
    @map = map

    @potential_moves = []

    @selected_image = Image["tile_selection.png"]
    @mouse_hover_image = Image["mouse_hover.png"]

    @selected = @hover_tile = nil
    @path = nil
    @moves_record = nil

    super(options)

    add_inputs(released_left_mouse_button: :left_click,
               released_right_mouse_button: :right_click)

    @map.factions.each do |faction|
      faction.subscribe :turn_ended do
        reset
      end
      faction.subscribe :turn_started do
        reset
      end
    end
  end

  def update
    select nil if selected and selected.tile.nil?
    super
  end

  def selected_can_be_controlled?
    selected and selected.active? and selected.faction.player.is_a?(Players::Human) and
        @map.factions.all? {|f| f.entities.none?(&:busy?) }
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
      @path.draw if @path

    elsif @hover_tile
      color = (@hover_tile.empty? or @hover_tile.object.inactive?) ? Color::BLUE : Color::CYAN
      @mouse_hover_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, color
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
          selected.use_ability :melee, path.last
      end

      calculate_path
      calculate_potential_moves
    elsif @hover_tile and @hover_tile.object
      # Select a character to move.
      select @hover_tile.object
    end
  end

  def select(object)
    @selected = object
    @moves_record = nil

    if selected and selected_can_be_controlled?
      calculate_path
      calculate_potential_moves
    else
      modify_occlusions @potential_moves, -1
      @potential_moves.clear

      modify_occlusions @path.tiles, -1 if @path
      @path = nil
    end
  end

  def reset
    if selected
      sel = selected
      select nil
      select sel
    end
  end

  def right_click
    select nil if selected
  end
end
end