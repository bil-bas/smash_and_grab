module SmashAndGrab::GameActions
class Ability < GameAction
  def can_be_undone?; ability.can_be_undone?; end
  def ability; @actor.ability @data[:ability]; end
  def do; ability.do @data; end
  def undo; ability.undo @data; end
  def save_data; @data; end

  # data is: Entity, data_hash (constructed by game)
  #      or: data_hash (reconstructed from saved data)
  def initialize(map, *data)
    @map = map

    case data.size
      when 2
        @actor = data[0]
        @data = data[1].merge(owner_id: @actor.id, type: :ability)
      when 1
        @data = data.first
        @actor = @map.object_by_id(@data[:owner_id])
      else
        raise data.to_s
    end
  end
end
end