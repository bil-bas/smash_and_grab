class GameAction::EndTurn < GameAction
  def initialize(map, *data)
    @map = map
    super()
  end

  def can_be_undone?; false; end

  def do
  end

  def undo
    # TODO: Need to be able to undo this when accessing history.
  end
end

