require_relative 'world'

class EditLevel < World
  SAVE_FOLDER = File.expand_path("config/levels", ROOT_PATH)
  QUICKSAVE_FILE = File.expand_path("01_bank.sgl", SAVE_FOLDER)
  OBJECT_TABS = [:tiles, :entities]

  def initialize
    super()

    @mouse_hover_image = Image["mouse_hover.png"]

    load_game QUICKSAVE_FILE

    on_input :right_mouse_button do
      case @tabs_group.value
        when :tiles
          @selector_group.value = @hover_tile.type if @hover_tile

        when :entities
          if @hover_tile and @hover_tile.entity
            @selector_group.value = @hover_tile.entity.type
          else
            @selector_group.value = :erase
          end

        when :objects

        when :walls

      end
    end
  end

  def create_gui
    vertical padding: 1, background_color: Color::BLACK do
      horizontal padding: 0 do
        button "Undo", padding_h: 1, font_height: 5 do
          undo_action
        end

        button "Redo", padding_h: 1, font_height: 5, align_h: :right do
          redo_action
        end
      end

      vertical padding: 0, spacing: 0 do
        @tabs_group = group do
          @tab_buttons = horizontal padding: 0, spacing: 2 do
            OBJECT_TABS.each do |name|
              radio_button(name, name, border_thickness: 0)
            end
          end

          subscribe :changed do |sender, value|
            current = @tab_buttons.find {|elem| elem.value == value }
            @tab_buttons.each {|t| t.enabled = (t != current) }

            setup_tab value
          end
        end

        @tab_contents = vertical padding: 0 do
          # put a tab in here at a later date.
        end
      end
    end

    @tabs_group.value = OBJECT_TABS.first
  end

  def setup_tab(tab)
    @tab_contents.clear

    case tab
      when :tiles
        unless defined? @tiles_window
          @tiles_window = Fidgit::ScrollWindow.new width: 45, height: 120 do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', 'none'

                Tile.config.each_pair do |type, data|
                  next if type == 'none'
                  radio_button '', type, icon: Tile.sprites[*data['spritesheet_position']],
                               tip: type, padding: 0, icon_options: { factor: 0.5 }
                end
              end
            end

            buttons.value = 'none'
          end
        end

        @selector_window = @tiles_window

      when :entities
        unless defined? @entities_window
          @entities_window = Fidgit::ScrollWindow.new width: 45, height: 120 do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', :erase

                Entity.config.each_pair do |type, data|
                  radio_button '', type, icon: Entity.sprites[*data['spritesheet_position']],
                               tip: type, padding: 0, icon_options: { factor: 0.25 }
                end
              end
            end

            buttons.value = :erase
          end
        end

        @selector_window = @entities_window

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

    @hover_tile.modify_occlusions -1 if @hover_tile

    @hover_tile = if  $window.mouse_x >= 0 and $window.mouse_x < $window.width and
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height
      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    @hover_tile.modify_occlusions +1 if @hover_tile

    if holding? :left_mouse_button and @hover_tile
      case @tabs_group.value
        when :tiles
          if @hover_tile.type != @selector_group.value
            @actions.do :set_tile_type, @hover_tile, @selector_group.value
          end

        when :entities
          if @selector_group.value == :erase
            @actions.do :erase_object, @hover_tile unless @hover_tile.empty?
          else
            if @hover_tile.empty? or
                (@hover_tile.entity and @hover_tile.entity.type != @selector_group.value)

              @actions.do :place_object, @hover_tile, @selector_group.value
            end
          end

        when :objects

      end
    end
  end

  def draw
    super()

    if @hover_tile
      $window.translate -@camera_offset_x, -@camera_offset_y do
        $window.scale @zoom do
          @mouse_hover_image.draw_rot @hover_tile.x, @hover_tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5
        end
      end
    end
  end
end
