module SmashAndGrab
module States
class MainMenu < Fidgit::GuiState
  PRELOAD_CLASSES = [Objects::Entity, Objects::Static, Tile, Objects::Vehicle, Wall]

  LOAD_FOLDER = File.expand_path("config/levels", EXTRACT_PATH)
  GAME_FILE = File.expand_path("01_bank.sgl", LOAD_FOLDER)

  def setup
    super

    @container.background_color = Color.rgb(0, 0, 25)

    vertical align: :center, padding: 0, spacing: 0 do
      horizontal align: :center do
        image_frame Objects::Static.sprites[1, 0], factor: 3

        vertical align: :center do
          label "Smash", font_height: 100, align: :center, color: Color::RED
          label "and", font_height: 60, align: :center, padding_top: -50, color: Color.rgb(200, 200, 200)
          label "Grab", font_height: 100, align: :center, padding_top: -45, color: Color::RED
        end

        image_frame Objects::Static.sprites[1, 0], factor: 3
      end

      horizontal align: :center do
        image_frame Objects::Entity.sprites[3, 1], factor: 4

        vertical align: :center do
          options = { width: 200, justify: :center }
          button "Single Player", options do
            push_game_state States::PlayLevel.new(GAME_FILE, Players::Human.new, Players::AI.new)
          end

          button "Round Robin", options do
            push_game_state States::PlayLevel.new(GAME_FILE, Players::Human.new, Players::Human.new)
          end

          button "AI vs AI", options do
            push_game_state States::PlayLevel.new(GAME_FILE, Players::AI.new, Players::AI.new)
          end

          button "Edit", options do
            push_game_state States::EditLevel.new(GAME_FILE)
          end

          button "Quit", options do
            exit
          end
        end

        image_frame Objects::Entity.sprites[7, 3], factor: 4
      end
    end
  end

  def update
    super

    # Preload.
    @preloads ||= PRELOAD_CLASSES.dup
    unless @preloads.empty?
      klass = @preloads.pop
      t = Time.now
      klass.sprites
      klass.config

      Log.log.debug { "Preloaded #{klass} in #{Time.now - t}s" }
    end
  end

  def finalize
    super
    @container.clear
  end
end
end
end