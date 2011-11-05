require_relative 'world'

class EditLevel < World
  SAVE_FOLDER = File.expand_path("config/levels", ROOT_PATH)
  QUICKSAVE_FILE = File.expand_path("01_bank.sgl", SAVE_FOLDER)
  OBJECT_TABS = [:tiles, :entities, :walls]
  GRID_COLOR = Color.rgba(150, 150, 150, 150)

  def initialize
    super()

    @mouse_hover_tile_image = Image["mouse_hover.png"]
    @mouse_hover_wall_image = Image["mouse_hover_wall.png"]

    @selected_wall = nil

    load_game QUICKSAVE_FILE

    on_input :right_mouse_button do

        case @tabs_group.value
          when :tiles
            @selector_group.value = @hover_tile.type if @hover_tile

          when :entities
            if @hover_tile
              if @hover_tile.entity
                @selector_group.value = @hover_tile.entity.type
              else
                @selector_group.value = :erase
              end
            end

          when :objects

          when :walls
            @selector_group.value = @hover_wall.type if @hover_wall

          else
            raise @tabs_group.value
      end
    end

    record_grid
  end

  def create_gui
    vertical padding: 1, background_color: Color::BLACK do
      vertical padding: 0, spacing: 0 do
        @tabs_group = group do
          @tab_buttons = horizontal padding: 0, spacing: 2 do
            OBJECT_TABS.each do |name|
              radio_button(name.to_s[0].capitalize, name, border_thickness: 0, tip: name.to_s.capitalize)
            end
          end

          subscribe :changed do |sender, value|
            current = @tab_buttons.find {|elem| elem.value == value }
            @tab_buttons.each {|t| t.enabled = (t != current) }
            current.color, current.background_color = current.background_color, current.color

            setup_tab value
          end
        end

        @tab_contents = vertical padding: 0 do
          # put a tab in here at a later date.
        end
      end

      horizontal padding: 0, padding_top: 5 do
        button "Undo", padding_h: 1, font_height: 5 do
          undo_action
        end

        button "Redo", padding_h: 1, font_height: 5 do
          redo_action
        end
      end
    end

    @tabs_group.value = OBJECT_TABS.first
  end

  def setup_tab(tab)
    @tab_contents.clear

    scroll_options = { width: 50, height: 120 }

    case tab
      when :tiles
        unless defined? @tiles_window
          @tiles_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', 'none'
                grid padding: 0, num_columns: 2 do
                  Tile.config.each_pair.sort.each do |type, data|
                    next if type == 'none'
                    radio_button '', type, icon: Tile.sprites[*data['spritesheet_position']],
                                 tip: type, padding: 0, icon_options: { factor: 0.5 }
                  end
                end
              end
            end

            buttons.value = 'none'
          end
        end

        @selector_window = @tiles_window

      when :entities
        unless defined? @entities_window
          @entities_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', :erase
                grid padding: 0, num_columns: 2 do

                  Entity.config.each_pair.sort.each do |type, data|
                    radio_button '', type, icon: Entity.sprites[*data['spritesheet_position']],
                                 tip: "#{type} (#{data['faction']})", padding: 0, icon_options: { factor: 0.25 }
                  end
                end
              end
            end

            buttons.value = :erase
          end
        end

        @selector_window = @entities_window

      when :walls
        unless defined? @walls_window
          @walls_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', 'none'
                grid padding: 0, num_columns: 3 do
                  Wall.config.each_pair.sort.each do |type, data|
                    next if type == 'none'
                    radio_button '', type, icon: Wall.sprites[*(data['spritesheet_positions']['vertical'])],
                                 tip: type, padding: 0, icon_options: { factor: 0.25 }
                  end
                end
              end
            end

            buttons.value = 'none'
          end
        end

        @selector_window = @walls_window

      else
        raise tab.to_s
    end

    @tab_contents.add @selector_window
    @selector_group = @selector_window.content[0]
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
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height
      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    if tile and @tabs_group.value == :walls
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
      case @tabs_group.value
        when :tiles
          if @hover_tile
            if @hover_tile.type != @selector_group.value
              @actions.do :set_tile_type, @hover_tile, @selector_group.value
            end
          end

        when :entities
          if @hover_tile
            if @selector_group.value == :erase
              @actions.do :erase_object, @hover_tile unless @hover_tile.empty?
            else
              if @hover_tile.empty? or
                  (@hover_tile.entity and @hover_tile.entity.type != @selector_group.value)

                @actions.do :place_object, @hover_tile, Entity, @selector_group.value
              end
            end
          end

        when :walls
          if @hover_wall
            if @hover_wall and @hover_wall.type != @selector_group.value
              @actions.do :set_wall_type, @hover_wall, @selector_group.value
            end
          end

        else
          raise @tabs_group.value
      end
    end
  end

  def record_grid
    @grid_record = $window.record do
      tiles = map.instance_variable_get(:@tiles)

      # Lines top to bottom.
      tiles.each do |row|
        tile = row.first
        $window.pixel.draw_rot tile.x - 16, tile.y, ZOrder::TILE_SELECTION, -26.55, 0, 0.5, row.size * 17.9, 1, GRID_COLOR
      end

      # Lines left to right.
      tiles.first.each do |tile|
        $window.pixel.draw_rot tile.x - 16, tile.y, ZOrder::TILE_SELECTION, +26.55, 0, 0.5, tiles.size * 17.9, 1, GRID_COLOR
      end
    end
  end

  def draw
    super()

    @grid_record.draw -@camera_offset_x, -@camera_offset_y, ZOrder::TILE_SELECTION, @zoom, @zoom

    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
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
