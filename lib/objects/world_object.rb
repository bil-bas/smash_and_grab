class WorldObject < GameObject 
  attr_accessor :z

  OUTLINE_SCALE = Image::THIN_OUTLINE_SCALE
  
  def initialize(options = {})    
    options = {
        rotation_center: :bottom_center,
        z: 0,
    }.merge! options  
  
    create_shadow(options[:position]) 
  
    @z = options[:z]

    super(options)

    @image = @image.thin_outlined if @image
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
    @@shadow.draw_rot x, y, y - z, 0, 0.5, 0.5, 1, 0.5

    @image.draw_rot x, y + 1.5, y - z, 0, 0.5, 1, OUTLINE_SCALE * factor_x, OUTLINE_SCALE
  end
end