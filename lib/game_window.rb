class GameWindow < Chingu::Window
  attr_reader :pixel

  def initialize
    super(800, 600, false)
  end

  def setup
    enable_undocumented_retrofication

    # Ensure these are loaded into a single texture before we load anything else at all!
    # Reason is so we can safely use record{} with them.
    Tile.sprites
    Path.sprites

    @pixel = Image.create 1, 1
    @pixel.clear color: :white

    self.caption = "Smash and Grab - By Spooner [Escape - exit; Space - end turn; F5/F6 - quicksave/load; G - grid; Arrows - scroll]"

    self.cursor = false

    push_game_state MainMenu
  end
end