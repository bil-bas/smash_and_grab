# Hack because I've forgotten how to do this correctly!
class Fidgit::Element
  attr_accessor :tip

  alias_method :old_initialize, :initialize
  def initialize(options = {}, &block)
    options[:z] = SmashAndGrab::ZOrder::GUI
    old_initialize options, &block
  end
end