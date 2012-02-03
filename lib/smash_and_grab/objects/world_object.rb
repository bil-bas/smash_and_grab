module SmashAndGrab
module Objects
class WorldObject < GameObject
  include Log
  include Fidgit::Event
  extend Forwardable

  def_delegators :@tile, :map, :grid_position, :grid_x, :grid_y

  attr_reader :tile

  attr_accessor :z

  def id; @map.id_for_object(self); end
  def blocks_sight?; true; end
  def exerts_zoc?; false; end
  def fills_tile_on_minimap?; false; end
  def casts_shadow?; true; end

  OUTLINE_SCALE = Image::THIN_OUTLINE_SCALE

  def initialize(map, data, options = {})
    options = {
        rotation_center: :bottom_center,
        z: 0,
    }.merge! options

    super(options)

    @map = map
    @map << self

    self.tile = data[:tile] ? @map.tile_at_grid(*data[:tile]) : nil

    @z = options[:z]

    log.debug { "Created #{self}" }
  end

  def tile=(tile)
    @tile.remove self if @tile

    @tile = tile
    self.x, self.y = tile.x, tile.y if @tile
    @recorded_shadow = nil

    @tile << self if @tile

    @tile
  end

  # Iterates through all tiles this object sits on.
  def tiles(&block)
    yield @tile
  end
 
  def draw
    # Draw a shadow
    @recorded_shadow ||= $window.record(1, 1) do
      if casts_shadow?
        color = Color.rgba(0, 0, 0, (alpha * 0.3).to_i)

        shadow_scale = 0.5
        shadow_height = height * shadow_scale * 0.5
        shadow_base = z * shadow_scale
        skew = shadow_height * shadow_scale

        top_left = [@x - skew - (@z * shadow_scale) + 2, @y - shadow_height - shadow_base + 1.25, color]
        top_right = [@x - skew - width * 0.5 - (@z * shadow_scale) + 2, @y - shadow_height - shadow_base + 1.25, color]
        bottom_left = [@x - (width * 0.5 - @z) * shadow_scale + 2, @y - shadow_base + 1.25, color]
        bottom_right = [@x + (width * 0.5 + @z) * shadow_scale + 2, @y - shadow_base + 1.25, color]

        if factor_x < 0
          image.draw_as_quad(*top_left, *top_right, *bottom_left, *bottom_right, ZOrder::SHADOWS)
        else
          image.draw_as_quad(*top_right, *top_left, *bottom_right, *bottom_left, ZOrder::SHADOWS)
        end
      end
    end

    @recorded_shadow.draw 0, 0, ZOrder::SHADOWS

    @image.draw_rot @x, @y + 2.5, @y, 0, 0.5, 1, OUTLINE_SCALE * @factor_x, OUTLINE_SCALE
  end

  def destroy
    self.tile = nil
    map.remove self

    super
  end
end
end
end