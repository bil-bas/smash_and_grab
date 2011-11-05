class EditorAction::EraseObject < EditorAction
  def initialize(tile)
    @tile = tile
    @object = @tile.objects.last
  end

  def do
    @tile.remove @object
    @tile.map.remove @object
  end

  def undo
    @tile.map << @object
    @tile << @object
  end
end