require_relative 'world'

class PlayLevel < World
  SAVE_FOLDER = File.expand_path("saves", ROOT_PATH)
  LOAD_FOLDER = File.expand_path("config/levels", EXTRACT_PATH)
  QUICKSAVE_FILE = File.expand_path("quicksave.sgs", SAVE_FOLDER)
  AUTOSAVE_FILE = File.expand_path("autosave.sgs", SAVE_FOLDER)
  ORIGINAL_FILE = File.expand_path("01_bank.sgl", LOAD_FOLDER)

  def initialize
    super()

    add_inputs(space: :end_turn)

    @players = [Player::Human.new, Player::AI.new, Player::AI.new]

    load_game ORIGINAL_FILE

    @players.each.with_index do |player, i|
      map.factions[i].player = player
      player.faction = map.factions[i]
    end

    save_game AUTOSAVE_FILE

    @mouse_selection = MouseSelection.new @map
  end

  def create_gui
    # Unit roster.
    @container = Fidgit::Container.new

    Fidgit::Horizontal.new parent: @container, spacing: 2, padding: 0 do
      group do
        vertical padding: 1, spacing: 2, background_color: Color::BLACK do
          [@map.baddies.size, 8].min.times do |i|
            horizontal background_color: Color::BLUE, padding: 0 do
              image_frame @map.baddies[i].image, factor: 0.25, padding: 0, background_color: Color::GRAY
              vertical padding: 0, spacing: 0 do
                label "##{i + 1}", font_height: 3.5
                label "bar1", font_height: 3.5
                label "bar2", font_height: 3.5
                label "icons", font_height: 3.5
              end
            end
          end
        end
      end
    end

    # Info panel.
    info_panel = Fidgit::Horizontal.new parent: @container, x: 35, y: 120, padding: 1, spacing: 2, background_color: Color::BLACK do
      image_frame @map.baddies[0].image, factor: 0.25, padding: 0, background_color: Color::GRAY
      text_area text: "Detailed info about the currently selected super-chicken (of prodigious size).\nAnd superpower buttons ......",
                width: 90, font_height: 4
    end
    info_panel.x, info_panel.y = ($window.width / 4 - info_panel.width) / 2, $window.height / 4 - info_panel.height

    # Button box.
    button_box = Fidgit::Vertical.new parent: @container, padding: 1, spacing: 2, background_color: Color::BLACK do
      horizontal padding: 0 do
        button "Undo", padding_h: 1, font_height: 5 do
          undo_action
        end

        button "Redo", padding_h: 1, font_height: 5, align_h: :right do
          redo_action
        end
      end

      button "End turn" do
        end_turn
      end
    end

    button_box.x, button_box.y = $window.width / 4 - button_box.width, $window.height / 4 - button_box.height
  end

  def end_turn
    @mouse_selection.select nil
    @map.active_faction.end_turn
    save_game AUTOSAVE_FILE
  end

  def undo_action
    selection = @mouse_selection.selected
    @mouse_selection.select nil
    @map.actions.undo if @map.actions.can_undo?
    @mouse_selection.select selection if selection
  end

  def redo_action
    selection = @mouse_selection.selected
    @mouse_selection.select nil
    @map.actions.redo if @map.actions.can_redo?
    @mouse_selection.select selection if selection
  end

  def quicksave
    save_game QUICKSAVE_FILE
  end

  def quickload
    load_game QUICKSAVE_FILE
  end

  def map=(map)
    super(map)

    @mouse_selection = MouseSelection.new @map

    map
  end

  def draw
    super

    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        @mouse_selection.draw @camera_offset_x, @camera_offset_y, @zoom
        @map.draw_grid @camera_offset_x, @camera_offset_y, @zoom if holding? :g
      end
    end

    @font.draw "Turn: #{@map.turn + 1} Player: #{@map.active_faction}", 220, 35, ZOrder::GUI

    active = @mouse_selection.selected
    status_text = active ? "'#{active.name}' #{active.grid_position} #{active.health} HP / #{active.mp} MP / #{active.ap} AP" : "???"
    @font.draw status_text, 200, 475, ZOrder::GUI

    @font.draw "Turn: #{@map.turn + 1} Player: #{@map.active_faction}", 220, 35, ZOrder::GUI
  end

  def update
    super

    @mouse_selection.tile = if  $window.mouse_x >= 0 and $window.mouse_x < $window.width and
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height and
                                @container.each.none? {|e| e.hit? $window.mouse_x / 4, $window.mouse_y / 4 }

      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    @mouse_selection.update

    @map.active_faction.player.update
  end
end
