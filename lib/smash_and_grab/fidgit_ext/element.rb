class Fidgit::Element
  attr_accessor :tip
  attr_writer :shown
  def shown?; @shown; end

  alias_method :old_initialize, :initialize
  def initialize(options = {}, &block)
    @shown = true
    options[:z] = SmashAndGrab::ZOrder::GUI
    old_initialize options, &block
  end

  alias_method :old_draw, :draw
  def draw
    old_draw if shown?
  end

  alias_method :old_hit?, :hit?
  def hit?(x, y)
    if shown?
      old_hit?(x, y)
    else
      false
    end
  end
end

