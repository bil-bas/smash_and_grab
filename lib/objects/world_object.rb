class WorldObject < GameObject
  extend Forwardable

  def_delegators :@tile, :map, :grid_position, :grid_x, :grid_y

  attr_reader :tile

  attr_accessor :z

  OUTLINE_SCALE = Image::THIN_OUTLINE_SCALE

  def initialize(tile, options = {})
    options = {
        rotation_center: :bottom_center,
        z: 0,
    }.merge! options  
  
    create_shadow(options[:position]) 
  
    @z = options[:z]
    @tile = tile

    super(options)

    @tile.map << self
    @tile << self
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
    @@shadow.draw_rot x, y, ZOrder::SHADOW, 0, 0.5, 0.5, 1, 0.5

    @image.draw_rot x, y + 2.5, y - z, 0, 0.5, 1, OUTLINE_SCALE * factor_x, OUTLINE_SCALE
  end

  def destroy
    tile.remove self
    map.remove self

    super
  end
end