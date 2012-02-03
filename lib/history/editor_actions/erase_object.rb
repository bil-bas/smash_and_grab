module SmashAndGrab
module EditorActions
class EraseObject < EditorAction
  def initialize(tile)
    @tile = tile
    @object = @tile.object
  end

  def do
    @object.tile = nil
    @tile.map.remove @object
  end

  def undo
    @tile.map << @object
    @object.tile = @tile
  end
end
end
end