class EditorAction::SetWallType < EditorAction
  def initialize(wall, new_type)
    @wall, @new_type = wall, new_type
    @old_type = @wall.type
  end

  def do
    @wall.type = @new_type
  end

  def undo
    @wall.type = @old_type
  end
end