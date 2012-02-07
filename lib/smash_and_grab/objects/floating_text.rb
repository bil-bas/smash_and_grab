module SmashAndGrab
module Objects
class FloatingText < GameObject
  FONT_SIZE = 16

  def initialize(text, options = {})
    super(options)

    @final_y = y - 60
    @text = text
    @font = Font[FONT_NAME, FONT_SIZE]

    parent.map.add_effect self
  end

  def update
    self.y -= 1 # TODO: scale this with FPS.
    parent.map.remove_effect(self) if y < @final_y
  end

  def draw
    @font.draw_rel @text, x, y, zorder, 0.5, 0.5, 1, 1, color
  end
end
end
end