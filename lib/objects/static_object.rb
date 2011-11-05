require_relative "world_object"

class StaticObject < WorldObject
  CLASS = 'object'

  def to_json(*a)
    {
        DATA_CLASS => CLASS,
        DATA_TYPE => @type,
        DATA_ID => id,
        DATA_TILE => grid_position,
    }.to_json(*a)
  end
end