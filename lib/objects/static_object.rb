require_relative "world_object"

class StaticObject < WorldObject
  attr_reader :tile
  
  def initialize(grid_position, options = {})       
    super(options)
    @tile = parent.map.tile_at_grid(*grid_position)    
    @tile.add_object(self)
  end
end