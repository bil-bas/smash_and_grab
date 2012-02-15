require_relative 'world'

module SmashAndGrab
module States
class EditLevel < World
  PLACEMENT_COLOR = Color.rgba(255, 255, 255, 190)
  FACTIONS = [:baddies, :goodies, :bystanders]

  def initialize(file)
    super()

    @mouse_hover_tile_image = Image["mouse_hover.png"]
    @mouse_hover_wall_image = Image["mouse_hover_wall.png"]

    @selected_wall = nil

    factions = FACTIONS.map do |f|
      Factions.const_get(f.capitalize).new
    end

    load_game file, factions

    on_input :right_mouse_button do
      @selector.pick_up(@hover_tile, @hover_wall)
    end
  end

  def assign_entities_to_factions
    map.world_objects.grep(Objects::Entity).each do |o|
      o.faction = map.factions[FACTIONS.index o.default_faction_type]
    end
  end

  def create_gui
    @container = Fidgit::Container.new do |container|
      @minimap = Gui::Minimap.new parent: container

      @selector = Gui::EditorSelector.new parent: container

      @button_box = vertical parent: container, padding: 4, spacing: 8, background_color: Color::BLACK do
        horizontal padding: 0 do
          @undo_button = button "Undo", padding_h: 4, font_height: 16 do
            undo_action
          end

          @redo_button = button "Redo", padding_h: 4, font_height: 16 do
            redo_action
          end
        end
      end

      @button_box.x, @button_box.y = $window.width - @button_box.width, $window.height - @button_box.height
    end
  end

  def undo_action
    @actions.undo if @actions.can_undo?
  end

  def redo_action
    @actions.redo if @actions.can_redo?
  end

  def quicksave
    save_game_as @editing_file
  end

  def quickload
    load_game @editing_file
  end

  def load_game(file, factions)
    super file, factions, start: false
    @editing_file = file
    @actions = EditorActionHistory.new
  end

  def update
    super()

    tile = if $window.mouse_x >= 0 and $window.mouse_x < $window.width and
              $window.mouse_y >= 0 and $window.mouse_y < $window.height and
              @container.each.none? {|e| e.hit? $window.mouse_x, $window.mouse_y }
      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    if tile and @selector.tab == :walls
      x, y = (@camera_offset_x + $window.mouse_x) / @zoom, (@camera_offset_y + $window.mouse_y) / @zoom

      wall = if x < tile.x - 3 and y < tile.y - 1
        tile.wall :up
      elsif x < tile.x - 3 and y > tile.y + 1
        tile.wall :left
      elsif x > tile.x + 3 and y < tile.y - 1
        tile.wall :right
      elsif x > tile.x + 3 and y > tile.y + 1
        tile.wall :down
      else
        nil
      end

      if @hover_wall != wall
        @hover_wall.tiles.each {|t| t.modify_occlusions -1} if @hover_wall
        @hover_wall = wall
        @hover_wall.tiles.each {|t| t.modify_occlusions +1} if @hover_wall
      end

      tile = nil
    else
      @hover_wall.tiles.each {|t| t.modify_occlusions -1} if @hover_wall
      @hover_wall = nil
    end

    if @hover_tile != tile
      @hover_tile.modify_occlusions -1 if @hover_tile
      @hover_tile = tile
      @hover_tile.modify_occlusions +1 if @hover_tile
    end

    if holding? :left_mouse_button
      case @selector.tab
        when :tiles                         then place_tile
        when :entities, :objects, :vehicles then place_entity
        when :walls                         then place_wall
        else
          raise @selector.tab
      end
    end

    @undo_button.enabled = @actions.can_undo?
    @redo_button.enabled = @actions.can_redo?
  end

  def place_wall
    if @hover_wall
      if @hover_wall and @hover_wall.type != @selector.selected
        @actions.do :set_wall_type, @hover_wall, @selector.selected
      end
    end
  end

  def place_entity
    klass = case @selector.tab
              when :entities then Objects::Entity
              when :objects then Objects::Static
              when :vehicles then Objects::Vehicle
            end

    if @hover_tile
      if @selector.selected == :erase
        @actions.do :erase_object, @hover_tile unless @hover_tile.empty?
      else
        if @hover_tile.empty? or
            (@hover_tile.object and @hover_tile.object.type != @selector.selected)

          @actions.do :place_object, @hover_tile, klass, @selector.selected
        end
      end
    end
  end

  def place_tile
    if @hover_tile
      if @hover_tile.type != @selector.selected
        @actions.do :set_tile_type, @hover_tile, @selector.selected
      end
    end
  end

  def draw
    super()

    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        @map.draw_grid unless holding? :g

        if @hover_wall
          tile = @hover_wall.tiles.first
          offset_x, offset_y = if @hover_wall.orientation == :vertical
            [+8, +4]
          else
            [-8, +4]
          end

          factor_x = (@hover_wall.orientation == :vertical) ? -1 : 1
          @mouse_hover_wall_image.draw_rot tile.x + offset_x, tile.y + offset_y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, factor_x

          image = @selector.icon_for @selector.selected
          if image
            image.draw_rot tile.x, tile.y + 8, tile.y + 8, 0, 0.5, 1, -factor_x, 1, PLACEMENT_COLOR
          end

        elsif @hover_tile
          @mouse_hover_tile_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5

          image = @selector.icon_for @selector.selected
          if image
            offset_y, scale, rel_x = if @selector.tab == :tiles
                                       [0, 1, 0.5]
                                     else
                                       [2.5, 0.5, 1]
                                     end
            image.draw_rot @hover_tile.x, @hover_tile.y + offset_y, @hover_tile.y, 0, 0.5, rel_x, scale, scale, PLACEMENT_COLOR
          end
        end
      end
    end
  end
end
end
end