require_relative 'world'

class EditLevel < World
  SAVE_FOLDER = File.expand_path("config/levels", ROOT_PATH)
  QUICKSAVE_FILE = File.expand_path("01_bank.sgl", SAVE_FOLDER)
  
  def initialize
    super()

    load_game QUICKSAVE_FILE
  end

  def create_gui
    horizontal spacing: 0, padding: 0 do
      horizontal spacing: 2, padding: 0 do
        horizontal padding: 0 do
          vertical padding: 1, spacing: 2, background_color: Color::BLACK do
            scroll_window width: 45, height: 130 do
              group do
                vertical padding: 1 do
                  radio_button 'blank', tip: 'Null tile'
                  Tile.config.each_pair do |type, data|
                    next if type == 'none'
                    radio_button '', data, icon: Tile.sprites[*data['spritesheet_position']], tip: type
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
  end

  def undo_action
    # TODO: Create editor actions.
  end

  def redo_action
    # TODO: Create editor actions.
  end

  def quicksave
    save_game QUICKSAVE_FILE
  end

  def quickload
    load_game QUICKSAVE_FILE
  end
end
