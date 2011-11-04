require_relative 'action_history'

class EditorActionHistory < ActionHistory
  def create_action(type, *args); EditorAction.const_get(Inflector.camelize(type)).new *args; end

  def initialize
    super(1000)
  end
end

class EditorAction < Fidgit::History::Action
  class SetTileType < self
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

  # --------------------------

  include Log

  def can_be_undone?; true; end
end