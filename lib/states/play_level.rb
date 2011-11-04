require_relative 'world'

class PlayLevel < World
  SAVE_FOLDER = File.expand_path("saves", ROOT_PATH)
  QUICKSAVE_FILE = File.expand_path("quicksave.sgs", SAVE_FOLDER)
  AUTOSAVE_FILE = File.expand_path("autosave.sgs", SAVE_FOLDER)

  def initialize
    # Create a map.
    possible_tiles = [
        *(['concrete'] * 20),
        *(['grass'] * 4),
        *(['lava'] * 1),
    ]

    map_size = 50

    tile_data = Array.new(map_size) { Array.new(map_size) { possible_tiles.sample } }

    # Create a little house.
    wall_data = [
        # Back wall.
        { "type" => "high_concrete_wall", "tiles" => [[1, 2], [1, 3]] },
        { "type" => "high_concrete_wall_with_window", "tiles" => [[2, 2], [2, 3]] },
        { "type" => "high_concrete_wall_with_window", "tiles" => [[3, 2], [3, 3]] },
        { "type" => "high_concrete_wall", "tiles" => [[4, 2], [4, 3]] },

        # Left wall
        { "type" => "high_concrete_wall", "tiles" => [[0, 3], [1, 3]] },
        # { "type" => "high_concrete_wall", "tiles" => [[0, 4], [1, 4]] },
        { "type" => "high_concrete_wall", "tiles" => [[0, 5], [1, 5]] },
        { "type" => "high_concrete_wall", "tiles" => [[0, 6], [1, 6]] },

        # Front wall.
        { "type" => "high_concrete_wall", "tiles" => [[1, 6], [1, 7]] },
        { "type" => "high_concrete_wall_with_window", "tiles" => [[2, 6], [2, 7]] },
        { "type" => "high_concrete_wall_with_window", "tiles" => [[3, 6], [3, 7]] },
        { "type" => "high_concrete_wall", "tiles" => [[4, 6], [4, 7]] },

        # Right wall
        { "type" => "high_concrete_wall", "tiles" => [[4, 3], [5, 3]] },
        { "type" => "high_concrete_wall", "tiles" => [[4, 4], [5, 4]] },
        { "type" => "high_concrete_wall", "tiles" => [[4, 5], [5, 5]] },
        { "type" => "high_concrete_wall", "tiles" => [[4, 6], [5, 6]] },


        # Garden
        # Back wall.
        { "type" => "low_fence", "tiles" => [[5, 2], [5, 3]] },
        { "type" => "low_fence", "tiles" => [[6, 2], [6, 3]] },
        #{ "type" => "low_fence", "tiles" => [[7, 2], [7, 3]] },
        { "type" => "low_fence", "tiles" => [[8, 2], [8, 3]] },

        # Front wall.
        { "type" => "low_brick_wall", "tiles" => [[5, 6], [5, 7]] },
        { "type" => "low_brick_wall", "tiles" => [[6, 6], [6, 7]] },
        { "type" => "low_brick_wall", "tiles" => [[7, 6], [7, 7]] },
        { "type" => "low_brick_wall", "tiles" => [[8, 6], [8, 7]] },

        # Right wall
        { "type" => "low_fence", "tiles" => [[8, 3], [9, 3]] },
        { "type" => "low_fence", "tiles" => [[8, 4], [9, 4]] },
        { "type" => "low_brick_wall", "tiles" => [[8, 5], [9, 5]] },
        { "type" => "low_brick_wall", "tiles" => [[8, 6], [9, 6]] },
    ]

    entity_data = Array.new(200) do
      {
          "type" => Entity.types.sample,
          "tile" => [rand(map_size), rand(map_size)],
          "facing" => ['left', 'right'].sample,
      }
    end

    self.map = Map.new "tiles" => tile_data, "walls" => wall_data, "entities" => entity_data, "objects" => [], 'actions' => []

    super()

    add_inputs(space: :end_turn)

    save_game AUTOSAVE_FILE

    @mouse_selection = MouseSelection.new @map
  end

  def create_gui
    horizontal spacing: 0, padding: 0 do
      horizontal spacing: 2, padding: 0 do
        group do
          vertical padding: 1, spacing: 2, background_color: Color::BLACK, do
            8.times do |i|
              horizontal background_color: Color::BLUE, padding: 0 do
                image_frame @map.baddies[i].image, factor: 0.25, padding: 0, background_color: Color::GRAY
                vertical padding: 0, spacing: 0 do
                  label "##{i + 1}", font_size: 4.5
                  label "bar1", font_height: 3.5
                  label "bar2", font_height: 3.5
                  label "icons", font_height: 3.5
                end
              end
            end
          end
        end

        horizontal padding: 0, padding_top: 125 do
          horizontal padding: 1, spacing: 2, background_color: Color::BLACK do
            image_frame @map.entities[0].image, factor: 0.25, padding: 0, background_color: Color::GRAY
            text_area text: "Detailed info about the currently selected super-chicken (of prodigious size).\nAnd superpower buttons ......",
                      width: 100, font_height: 4
          end

          vertical padding: 1, spacing: 2, background_color: Color::BLACK do
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
        end
      end
    end
  end

  def end_turn
    @mouse_selection.select nil
    @map.end_turn
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
      end
    end

    @font.draw "Turn: #{@map.turn + 1} Player: #{@map.active_faction}", 200, 35, ZOrder::GUI

    active = @mouse_selection.selected
    status_text = active ? "'#{active.name}' #{active.grid_position} #{active.health} HP / #{active.mp} MP / #{active.ap} AP" : "???"
    @font.draw status_text, 200, 475, ZOrder::GUI

    @font.draw "Turn: #{@map.turn + 1} Player: #{@map.active_faction}", 200, 35, ZOrder::GUI
  end

  def update
    super

    @mouse_selection.tile = if  $window.mouse_x >= 0 and $window.mouse_x < $window.width and
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height
      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    @mouse_selection.update
  end
end
