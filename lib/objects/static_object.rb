require_relative "world_object"

class StaticObject < WorldObject
  attr_reader :tile
  
  def initialize(tile, options = {})
    @tile = tile

    super(options)

    @tile.add_object(self)
  end
end