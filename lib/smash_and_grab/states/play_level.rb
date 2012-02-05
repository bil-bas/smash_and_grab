require_relative 'world'

module SmashAndGrab
module States
class PlayLevel < World
  attr_reader :info_panel

  def initialize(file)
    super()

    add_inputs(space: :end_turn)

    @players = [Players::Human.new, Players::AI.new, Players::AI.new]

    @quicksaved = false

    load_game file

    @players.each.with_index do |player, i|
      map.factions[i].player = player
      player.faction = map.factions[i]
    end

    save_game_as AUTOSAVE_FILE

    @mouse_selection = MouseSelection.new @map
  end

  def create_gui
    @container = Fidgit::Container.new do |container|
      @minimap = Gui::Minimap.new parent: container

      # Unit roster.
      @summary_bar = vertical parent: container, padding: 4, spacing: 4, background_color: Color::BLACK do |packer|
        [@map.baddies.size, 8].min.times do |i|
          baddy = @map.baddies[i]
          summary = Gui::EntitySummary.new baddy, parent: packer
          summary.subscribe :left_mouse_button do
            @mouse_selection.selected = baddy if baddy.alive?
            @info_panel.object = baddy
          end
        end
      end

      # Info panel.
      @info_panel = Gui::InfoPanel.new parent: container
      @info_panel.object = @map.baddies[0]

      # Button box.
      @button_box = vertical parent: container, padding: 4, spacing: 8, width: 150, background_color: Color::BLACK do
        @turn_label = label " ", font_height: 14

        button "End turn" do
          end_turn
        end

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

  def end_turn
    @map.active_faction.end_turn
    save_game_as AUTOSAVE_FILE
  end

  def undo_action
    selection = @mouse_selection.selected
    @mouse_selection.selected = nil
    @map.actions.undo if @map.actions.can_undo?
    @mouse_selection.selected = selection if selection
  end

  def redo_action
    selection = @mouse_selection.selected
    @mouse_selection.selected = nil
    @map.actions.redo if @map.actions.can_redo?
    @mouse_selection.selected =sd selection if selection
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
        @mouse_selection.draw
        @map.draw_grid if holding? :g
      end
    end
  end

  def update
    super

    @mouse_selection.tile = if  $window.mouse_x >= 0 and $window.mouse_x < $window.width and
                                $window.mouse_y >= 0 and $window.mouse_y < $window.height and
                                @container.each.none? {|e| e.hit? $window.mouse_x, $window.mouse_y }

      @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
         (@camera_offset_y + $window.mouse_y) / @zoom)
    else
      nil
    end

    @info_panel.object = @mouse_selection.selected

    @mouse_selection.update

    @map.active_faction.player.update

    @turn_label.text = "Turn: #{@map.turn + 1} (#{@map.active_faction})"

    @undo_button.enabled = @map.actions.can_undo?
    @redo_button.enabled = @map.actions.can_redo?
  end

  def quickload
    if @quicksaved
      switch_game_state self.class.new(QUICKSAVE_FILE)
    end
  end

  def quicksave
    save_game_as QUICKSAVE_FILE
    @quicksaved = true
  end
end
end
end
