class MainMenu < Fidgit::GuiState
  def setup
    super

    vertical align: :center do
      button "Play" do
        push_game_state PlayLevel
      end

      button "Edit" do
        push_game_state EditLevel
      end

      button "Quit" do
        exit
      end
    end
  end

  def finalize
    super
    @container.clear
  end
end