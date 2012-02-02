require_relative 'action_history'

class GameActionHistory < ActionHistory
  def create_action(type, *args); GameAction.const_get(Inflector.camelize(type)).new @map, *args; end

  def initialize(map, data)
    @map = map

    super(Float::INFINITY)

    if data
      @actions = data.map do |action_data|
        action_data = action_data
        GameAction.const_get(Inflector.camelize(action_data[:type])).new map, action_data
      end

      @last_done = @actions.size - 1
    end
  end
end

class GameAction < Fidgit::History::Action
  include Log

  def can_be_undone?; true; end

  def to_json(*a)
    {
      type: Inflector.underscore(Inflector.demodulize(self.class.name)),
    }.merge(save_data).to_json(*a)
  end

  def save_data
    {
    }
  end
end

require_folder 'history/game_actions', %w[ability end_turn]