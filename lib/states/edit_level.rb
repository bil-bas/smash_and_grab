require_relative 'world'

class EditLevel < World
  SAVE_FOLDER = File.expand_path("config/levels", EXTRACT_PATH)
  QUICKSAVE_FILE = File.expand_path("01_bank.sgl", SAVE_FOLDER)


  def initialize
    super()

    @mouse_hover_tile_image = Image["mouse_hover.png"]
    @mouse_hover_wall_image = Image["mouse_hover_wall.png"]

    @selected_wall = nil

    load_game QUICKSAVE_FILE

    on_input :right_mouse_button do
      @selector.pick_up(@hover_tile, @hover_wall)
    end
  end

  def create_gui
    @container = Fidgit::Container.new do |container|
      @minimap = Minimap.new parent: container

      @selector = EditorSelector.new parent: container

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
    save_game QUICKSAVE_FILE
  end

  def quickload
    load_game QUICKSAVE_FILE
  end

  def load_game(file)
    super
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
      @hover_wall = nil
    end

    if @hover_tile != tile
      @hover_tile.modify_occlusions -1 if @hover_tile
      @hover_tile = tile
      @hover_tile.modify_occlusions +1 if @hover_tile
    end

    if holding? :left_mouse_button
      case @selector.tab
        when :tiles
          if @hover_tile
            if @hover_tile.type != @selector.selected
              @actions.do :set_tile_type, @hover_tile, @selector.selected
            end
          end

        when :entities, :objects
          klass = (@selector.tab == :entities) ? Entity : StaticObject

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

        when :walls
          if @hover_wall
            if @hover_wall and @hover_wall.type != @selector.selected
              @actions.do :set_wall_type, @hover_wall, @selector.selected
            end
          end

        else
          raise @selector.tab
      end
    end

    @undo_button.enabled = @actions.can_undo?
    @redo_button.enabled = @actions.can_redo?
  end

  def draw
    super()

    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        @map.draw_grid @camera_offset_x, @camera_offset_y, @zoom unless holding? :g

        if @hover_wall
          tile = @hover_wall.tiles.first
          offset_x, offset_y = if @hover_wall.orientation == :vertical
            [+8, +4]
          else
            [-8, +4]
          end

          factor_x = (@hover_wall.orientation == :vertical) ? -1 : 1
          @mouse_hover_wall_image.draw_rot tile.x + offset_x, tile.y + offset_y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, factor_x

        elsif @hover_tile
          @mouse_hover_tile_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5
        end
      end
    end
  end
end
