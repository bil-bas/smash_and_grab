class GameAction < Fidgit::History::Action
  include Log

  class Move < self
    DATA_PATH = 'path'
    DATA_MOVEMENT_COST = 'movement_cost'

    def initialize(map, data)
      @map = map

      case data
        when Entity::Path
          @path = data.tiles
          @movement_cost = data.move_distance
          @time = Time.now
        when Hash
          @path = data[DATA_PATH].map {|x, y| @map.tile_at_grid(x, y) }
          @movement_cost = data[DATA_MOVEMENT_COST]
          @time = data[DATA_TIME]
        else
          raise
      end
    end

    def do
      object = @path.first.objects.last
      object.move(@path[1..-1], @movement_cost)
    end

    def undo
      object = @path.last.objects.last
      object.move(@path.reverse[1..-1], -@movement_cost)
    end

    def save_data
      {
        DATA_PATH => @path.map {|t| [t.grid_x, t.grid_y] },
        DATA_MOVEMENT_COST => @movement_cost,
      }
    end
  end

  class EndTurn < self
    def initialize(map, data)
      @map = map
    end

    def do

    end

    def end

    end
  end

  DATA_TYPE = 'type'
  DATA_TIME = 'timestamp'

  def to_json(*a)
    {
      DATA_TYPE => Inflector.demodulize(self.class.name),
      DATA_TIME => @time,
    }.merge(save_data).to_json(*a)
  end

  def save_data
    {
    }
  end
end


class ActionHistory < Fidgit::History
  DATA_ACTIONS = 'actions'

  def initialize(map, data)
    @map = map

    super(Float::INFINITY)

    if data
      @actions = data.map do |action_data|
        GameAction.const_get(action_data[GameAction::DATA_TYPE]).new map, action_data
      end

      @last_done = @actions.size - 1
    end
  end

  # Perform a History::Action, adding it to the history.
  # If there are currently any actions that have been undone, they will be permanently lost and cannot be redone.
  #
  # @param [History::Action] action Action to be performed
  def do(action)
    raise ArgumentError, "Parameter, 'action', expected to be a #{Action}, but received: #{action}" unless action.is_a? Action

    # Remove all undone actions when a new one is performed.
    if can_redo?
      if @last_done == -1
        @actions.clear
      else
        @actions = @actions[0..@last_done]
      end
    end

    # If history is too big, remove the oldest action.
    if @actions.size >= @max_size
      @actions.shift
    end

    @last_done = @actions.size
    @actions << action
    action.do

    nil
  end

  def to_json(*a)
    # Only save actions that have been performed. Discard the redo-list.
    if @last_done >= 0
      @actions[0..@last_done].to_json(*a)
    else
      [].to_json(*a)
    end
  end
end