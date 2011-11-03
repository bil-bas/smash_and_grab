# Hack because I've forgotten how to do this correctly!
class Fidgit::Element
  alias_method :old_initialize, :initialize
  def initialize(options = {}, &block)
    options[:z] = ZOrder::GUI
    old_initialize options, &block
  end
end