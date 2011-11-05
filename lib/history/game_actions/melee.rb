class GameAction::Melee < GameAction
  DATA_ATTACKER = 'attacker_id'
  DATA_DEFENDER = 'defender_id'

  def initialize(map, data)
    @map = map

    case data
      when MeleePath
        @attacker, @defender = data.attacker, data.defender
        @time = Time.now
      when Hash
        @attacker = @map.object_by_id data[DATA_ATTACKER]
        @defender = @map.object_by_id data[DATA_DEFENDER]
        @time = data[DATA_TIME]
      else
        raise data.to_s
    end
  end

  def do
    @attacker.melee(@defender)
  end

  def undo
    # TODO: Need to be able to undo this when accessing history.
  end

  def can_be_undone?; false; end

  def save_data
    {
      DATA_ATTACKER => @attacker.id,
      DATA_DEFENDER => @defender.id,
    }
  end
end
