class Tile < GameObject
  class Grass < Tile
  end
  
  class Concrete < Tile
  end
  
  WIDTH, HEIGHT = 32, 16
    
  attr_reader :objects, :z
  
  def initialize(grid_position, options = {})
    unless defined? @@sprites
      @@sprites = Image.load_tiles($window, File.expand_path("media/images/tiles.png", EXTRACT_PATH), 16, 16, true)
    end
    options[:image] = ([@@sprites[0]]+ [@@sprites[1]] * 5).sample
    @grid_position = grid_position
    options[:x] = (@grid_position[1] + @grid_position[0]) * WIDTH / 2
    options[:y] = (@grid_position[1] - @grid_position[0]) * HEIGHT / 2
    options[:rotation_center] = :center_center
    options[:zorder] = options[:y]

    @objects = []

    super(options)
  end

  
  def add_object(object)
    @objects << object
    object.x, object.y = [x, y]
  end
  
  def draw
    color = Color::WHITE
    @image.draw_as_quad x - WIDTH / 2, y,  color, # Left
                        x, y - HEIGHT / 2, color, # Top
                        x + WIDTH / 2, y,  color, # Right
                        x, y + HEIGHT / 2, color, # Bottom
                        zorder
  end
end