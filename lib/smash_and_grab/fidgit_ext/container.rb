class Fidgit::Container
  alias_method :old_hit_element, :hit_element
  def hit_element(x, y)
    if shown?
      old_hit_element(x, y)
    else
      nil
    end
  end
end