module SmashAndGrab
class GameWindow < Chingu::Window
  attr_reader :pixel

  def initialize
    if FULLSCREEN
      super(screen_width, screen_height, true)
    else
      super(800, 600, false)
    end
  end

  def setup
    enable_undocumented_retrofication

    # Ensure these are loaded into a single texture before we load anything else at all!
    # Reason is so we can safely use record{} with them.
    Tile.sprites
    Paths::Path.sprites

    @pixel = Image.create 1, 1
    @pixel.clear color: :white

    self.caption = "Smash and Grab - By Spooner [Escape - exit; Space - end turn; F5/F6 - quicksave/load; G - grid; Arrows - scroll]"

    self.cursor = false

    SmashAndGrab::Mixins::RollsDice.create_text_entities

    push_game_state States::MainMenu
  end
end
end