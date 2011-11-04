require_relative 'world'

class EditLevel < World
  SAVE_FOLDER = File.expand_path("config/levels", ROOT_PATH)
  QUICKSAVE_FILE = File.expand_path("01_bank.sgl", SAVE_FOLDER)
  
  def initialize
    super()

    @mouse_hover_image = Image["mouse_hover.png"]

    load_game QUICKSAVE_FILE
  end

  def create_gui
    horizontal spacing: 0, padding: 0 do
      horizontal spacing: 2, padding: 0 do
        horizontal padding: 0 do
          vertical padding: 1, spacing: 2, background_color: Color::BLACK do
            scroll_window width: 45, height: 130 do
              @tile_combo = group do
                vertical padding: 1 do
                  radio_button 'Blank', 'none', tip: 'Null tile'
                  Tile.config.each_pair do |type, data|
                    next if type == 'none'
                    radio_button '', type, icon: Tile.sprites[*data['spritesheet_position']], tip: type, padding: 0
                  end
                end
              end
            end

            horizontal padding: 0 do
              button "Undo", padding_h: 1, font_height: 5 do
                undo_action
              end

              button "Redo", padding_h: 1, font_height: 5, align_h: :right do
                redo_action
              end
            end
          end
        end
      end
    end

    @tile_combo.value = 'none'
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

    @hover_tile = if  $window.mouse_x >= 0 and $window.mouse_x < $window.width and
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height
      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    if holding? :left_mouse_button and @hover_tile
      if @hover_tile.type != @tile_combo.value
        @actions.do :set_tile_type, @hover_tile, @tile_combo.value
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
