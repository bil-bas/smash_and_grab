require_relative 'action_history'

class EditorActionHistory < ActionHistory
  def create_action(type, *args); EditorAction.const_get(Inflector.camelize(type)).new *args; end

  def initialize
    super(1000)
  end
end

class EditorAction < Fidgit::History::Action
  include Log

  def can_be_undone?; true; end
end

require_folder 'history/editor_actions', %w[place_object erase_object set_tile_type set_wall_type]