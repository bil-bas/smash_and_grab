module SmashAndGrab
module Objects
class WorldObject < GameObject
  include Log
  include Fidgit::Event
  extend Forwardable

  event :changed

  def_delegators :@tile, :map, :grid_position, :grid_x, :grid_y

  attr_reader :tile

  attr_reader :z
  def z=(z); @z = z; @recorded_shadow = nil; z; end

  def id; @map.id_for_object(self); end
  def blocks_sight?; true; end
  def exerts_zoc?; false; end
  def fills_tile_on_minimap?; false; end
  def casts_shadow?; true; end

  def t; R18n.get.t[Inflector.demodulize self.class.name][type]; end
  def name; t.name; end
  def colorized_name; name; end
  def base_color; Color::BLUE; end

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

    publish :changed if tile != @tile

    @tile
  end

  # Iterates through all tiles this object sits on.
  def tiles(&block)
    yield @tile
  end

  def factor_x=(factor_x)
    # Ensure that the shadow is redrawn.
    super factor_x
    @recorded_shadow = nil
    factor_x
  end

  def draw
    # Draw a shadow
    if casts_shadow?
      @recorded_shadow ||= $window.record(1, 1) do
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

      @recorded_shadow.draw 0, 0, ZOrder::SHADOWS
    end

    @image.draw_rot @x, @y + 2.5 - @z, @y, 0, 0.5, 1, OUTLINE_SCALE * @factor_x, OUTLINE_SCALE, color
  end

  def draw_base
    Image["tile_selection.png"].draw_rot x, y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, base_color
  end

  def busy?; false; end
  def active?; false; end

  def to_json(*a)
    to_hash.to_json *a
  end

  def to_hash
    {
        :class => self.class::CLASS,
        type: type,
        id: id,
        tile: tile ? grid_position : nil,
    }
  end

  def destroy
    map.remove self
    self.tile = nil

    super
  end
end
end
end