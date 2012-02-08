require_relative 'world'

module SmashAndGrab
module States
class PlayLevel < World
  include Fidgit::Event

  attr_reader :info_panel, :cursor_world_x, :cursor_world_y

  event :game_info
  event :game_heading

  # Players is villains
  def initialize(file, baddies_players, goodies_players)
    super()

    add_inputs(space: :end_turn)

    @players = {
      baddies: Array(baddies_players),
      goodies: Array(goodies_players),
      bystanders: [Players::AI.new],
    }

    @quicksaved = false
    @cursor_world_x = @cursor_world_x = nil

    factions = []

    @players.each_pair do |faction_name, players|
      players.each do |player|
        new_faction = Factions.const_get(faction_name.capitalize).new
        factions << new_faction
        player.faction = new_faction
      end
    end

    load_game file, factions

    # If loading a level, start the first turn, otherwise just keep going.
    name = File.basename(file).chomp(File.extname(file))
    if File.extname(file) == ".sgl"
      publish :game_heading, "=== Started #{name} ==="
      publish :game_info, ""
      map.factions.first.start_turn
    else
      faction = map.active_faction
      publish :game_heading, "=== Resuming #{name} in turn #{map.turn + 1} ==="
      publish :game_info, ""
      publish :game_heading,faction.class::TEXT_COLOR.colorize("#{faction.name}' turn (#{Inflector.demodulize faction.player.class})")
      publish :game_info, ""
    end

    save_game_as AUTOSAVE_FILE

    @mouse_selection = MouseSelection.new @map
  end

  def assign_entities_to_factions
    factions_by_type = map.factions.group_by {|f| Inflector.demodulize(f.class.name).downcase.to_sym }
    factions_by_type.each_pair do |faction_name, factions|
      entities = map.world_objects.grep(Objects::Entity).find_all {|o| o.default_faction_type == faction_name }
      # Split them up as evenly as possible if more than one player is controlling them.
      entities_per_faction = entities.size.fdiv(factions.size).ceil
      entities.each_slice(entities_per_faction).with_index do |entities, i|
        entities.each {|e| e.faction = factions[i] }
      end
    end
  end

  def create_gui
    @container = Fidgit::Container.new do |container|
      @minimap = Gui::Minimap.new parent: container

      # Unit roster for each human-controlled faction.
      @summaries_lists = {}

      # Create a summary list for each human-controlled faction.
      @map.factions.each do |faction|
        if faction.player.is_a? Players::Human
          @summaries_lists[faction] = Fidgit::Vertical.new padding: 4, spacing: 4 do |packer|
            # Put each entity into the list.
            faction.entities.each do |entity|
              summary = Gui::EntitySummary.new entity, parent: packer
              summary.subscribe :left_mouse_button do
                @mouse_selection.selected = entity if entity.alive?
                @info_panel.object = entity
              end
            end
          end

          # At the start of the turn, change in our summary list.
          # Means the last human player's list will be shown during the AI turns.
          faction.subscribe :turn_started do
            @summary_bar.clear
            @summary_bar.add @summaries_lists[faction]
          end

          # TODO: Add and remove entities to the lists as unit list changes.
          #faction.subscribe :entity_added do
          #end
          #faction.subscribe :entity_removed do
          #end
        end
      end

      # Will contain the summary lists.
      @summary_bar = vertical parent: container, padding: 0, spacing: 0, background_color: Color::BLACK

      # Info panel.
      @info_panel = Gui::InfoPanel.new self, parent: container

      # Button box.
      @button_box = vertical parent: container, padding: 4, spacing: 8, width: 150, background_color: Color::BLACK do
        @turn_label = label " ", font_height: 14

        @end_turn_button = button "End turn" do
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
    @mouse_selection.selected = selection if selection
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

      @cursor_world_x = (@camera_offset_x + $window.mouse_x) / @zoom
      @cursor_world_y = (@camera_offset_y + $window.mouse_y) / @zoom

      @map.tile_at_position @cursor_world_x, @cursor_world_y
    else
      @cursor_world_x = @cursor_world_y = nil

      nil
    end

    @info_panel.object = @mouse_selection.selected

    @mouse_selection.update

    @map.active_faction.player.update

    @turn_label.text = "Turn: #{@map.turn + 1} (#{@map.active_faction})"

    usable = @map.active_faction.player.human? && !@map.busy?
    @end_turn_button.enabled = usable
    @undo_button.enabled = usable && @map.actions.can_undo?
    @redo_button.enabled = usable && @map.actions.can_redo?
  end

  def quickload
    if @quicksaved
      switch_game_state self.class.new(QUICKSAVE_FILE, @players[:baddies], @players[:goodies])
    end
  end

  def quicksave
    publish :game_heading, "<<< Quick-saved >>>"
    save_game_as QUICKSAVE_FILE
    @quicksaved = true
  end
end
end
end
