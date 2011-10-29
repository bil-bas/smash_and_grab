class Wall < GameObject
  SPRITESHEET_HORIZONTAL, SPRITESHEET_VERTICAL = 0, 1

  # No wall - just let the user through.
  class None < self
    def blocks_sight?(person); false; end
    def blocks_movement?(person); false; end
    def spritesheet_pos; nil; end
    def minimap_color; Color::NONE; end
  end

  # Concrete walls.
  class HighConcreteWall < self
    def spritesheet_pos; [[1, 0], [2, 0]]; end
    def minimap_color; Color.rgb(100, 100, 100); end
  end

  class HighConcreteWallWindow < self
    def blocks_sight?(person); false; end
    def spritesheet_pos; [[1, 1], [2, 1]]; end
    def minimap_color; Color.rgb(150, 150, 150); end
  end
  
  WIDTH, HEIGHT = 32, 64
    
  attr_reader :objects, :grid_x, :grid_y, :cost

  def blocks_sight?(person); true; end
  def blocks_movement?(person); true; end

  def zorder; super + 0.01; end
  def to_s; "<#{self.class.name} [#{@tiles[0].grid_x}, #{@tiles[0].grid_y}] <=> [#{@tiles[1].grid_x}, #{@tiles[1].grid_y}]>"; end

  
  def initialize(tile1, tile2, options = {})
    @@sprites ||= SpriteSheet.new("walls.png", WIDTH, HEIGHT, 8)
    @tiles = [tile1, tile2].sort_by(&:y)

    options = {
        rotation_center: :bottom_center,
        x: @tiles.first.x,
        y: @tiles.first.y + HEIGHT / 8,
        zorder: @tiles.first.y + 0.01,
    }.merge! options

    @cost = options[:cost]
    @objects = []

    super(options)

    if @tiles.last.grid_y > @tiles.first.grid_y
      @tiles.last.add_wall :top, self
      @tiles.first.add_wall :bottom, self
      @image = spritesheet_pos ? @@sprites[*spritesheet_pos[SPRITESHEET_VERTICAL]] : nil
    else
      @tiles.last.add_wall :right, self
      @tiles.first.add_wall :left, self
      @image = spritesheet_pos ? @@sprites[*spritesheet_pos[SPRITESHEET_HORIZONTAL]] : nil
    end

    parent.add_object self
  end

  def destination(from, person)
    blocks_movement?(person) ? nil : (@tiles - [from]).first
  end

  def draw
    if @image
      # TODO: Visibility based on nearby objects.
      color = Color.rgba(255, 255, 255, 150)
      @image.draw_rot @x, @y, @zorder, 0, 0.5, 1, 1, 1, color
    end
  end
end