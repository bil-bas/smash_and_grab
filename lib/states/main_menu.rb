class MainMenu < Fidgit::GuiState
  def setup
    super

    @container.background_color = Color.rgb(0, 0, 25)

    vertical align: :center do
      horizontal align: :center do
        image_frame StaticObject.sprites[1, 0], factor: 3

        vertical align: :center do
          label "Smash", font_height: 100, align: :center, color: Color::RED
          label "and", font_height: 60, align: :center, padding_top: -50, color: Color.rgb(200, 200, 200)
          label "Grab", font_height: 100, align: :center, padding_top: -45, color: Color::RED
        end

        image_frame StaticObject.sprites[1, 0], factor: 3
      end

      horizontal align: :center do
        image_frame Entity.sprites[3, 1], factor: 4

        vertical align: :center do
          options = { width: 120, justify: :center }
          button "Play", options do
            push_game_state PlayLevel
          end

          button "Edit", options do
            push_game_state EditLevel
          end

          button "Quit", options do
            exit
          end
        end

        image_frame Entity.sprites[7, 3], factor: 4
      end
    end
  end

  def finalize
    super
    @container.clear
  end
end