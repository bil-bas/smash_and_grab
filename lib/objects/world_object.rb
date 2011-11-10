class WorldObject < GameObject
  include Log
  extend Forwardable

  DATA_CLASS = 'class'
  DATA_TYPE = 'type'
  DATA_ID = 'id'
  DATA_TILE = 'tile'

  def_delegators :@tile, :map, :grid_position, :grid_x, :grid_y

  attr_reader :tile

  attr_accessor :z

  def id; @map.id_for_object(self); end
  def blocks_sight?; true; end
  def exerts_zoc?; false; end

  OUTLINE_SCALE = Image::THIN_OUTLINE_SCALE

  def initialize(map, data, options = {})
    options = {
        rotation_center: :bottom_center,
        z: 0,
    }.merge! options
  
    create_shadow(options[:position])

    super(options)

    @map = map
    @map << self

    if data[DATA_TILE]
      @tile = @map.tile_at_grid(*data[DATA_TILE])
      @tile << self
    else
      @tile = nil
    end

    @z = options[:z]

    log.debug { "Created #{self}" }
  end

  def create_shadow(position)
    unless defined? @@shadow
      @@shadow = TexPlay.create_image $window, 32, 32
      #center = img.size / 2
      32.times do |x|
        32.times do |y|
          @@shadow.pixel(x, y, color: [0, 0, 0, 0.5 - distance(x, y, 15.5, 15.5) * 0.05])
        end
      end
    end
  end
 
  def draw
    @@shadow.draw_rot @x, @y, ZOrder::SHADOW, 0, 0.5, 0.5, 1, 0.5

    @image.draw_rot @x, @y + 2.5, @y, 0, 0.5, 1, OUTLINE_SCALE * @factor_x, OUTLINE_SCALE
  end

  def destroy
    tile.remove self if tile
    map.remove self

    super
  end
end