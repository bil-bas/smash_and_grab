class GameAction::Sprint < GameAction
  DATA_ID = 'entity_id'
  DATA_BONUS = 'bonus'

  def initialize(map, data)
    @map = map

    case data
      when Entity
        @sprinter = data
        @sprint_bonus = @sprinter.sprint_bonus
        @time = Time.now
      when Hash
        @sprinter = map.object_by_id(data[DATA_ID])
        @bonus = data[DATA_BONUS]
        @time = data[DATA_TIME]
      else
        raise data.to_s
    end
  end

  def do
    @sprinter.movement_points += @sprint_bonus
    @sprinter.action_points = 0
  end

  def undo
    @sprinter.movement_points -= @sprint_bonus
    @sprinter.action_points = @sprinter.max_action_points
  end

  def save_data
    {
      DATA_ID => @sprinter.id,
      DATA_BONUS => @sprint_bonus,
    }
  end
end