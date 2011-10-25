require_relative "world_object"

class DynamicObject < WorldObject
  def initialize(grid_position, options = {})
    @velocity_z = 0

    super(grid_position, options)
  end

  def update
    if @velocity_z != 0 or z > 0
      @velocity_z -= 0.4
      self.z += @velocity_z

      if z <= 0
        self.z = 0
        @velocity_z = 0
      end
    end
  end
end