class EditorAction::SetTileType < EditorAction
  def initialize(tile, new_type)
    @tile, @new_type = tile, new_type
    @old_type = @tile.type
  end

  def do
    @tile.type = @new_type
  end

  def undo
    @tile.type = @old_type
  end
end
