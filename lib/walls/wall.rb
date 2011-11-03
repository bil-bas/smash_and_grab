class Wall < GameObject
  SPRITESHEET_HORIZONTAL, SPRITESHEET_VERTICAL = 0, 1

  SEMI_TRANSPARENT_COLOR = Color.rgba(255, 255, 255, 120)
  OPAQUE_COLOR = Color::WHITE

  DATA_TYPE = "type"
  DATA_TILES = "tiles"

  # No wall - just let the user through.
  class None < self
    def blocks_sight?(person); false; end
    def spritesheet_pos; nil; end
    def minimap_color; Color::NONE; end
    def movement_cost(person); 0; end
    def tiles_high; 0; end
  end

  # Concrete walls.
  class HighConcreteWall < self
    def spritesheet_pos; [[1, 0], [2, 0]]; end
    def minimap_color; Color.rgb(100, 100, 100); end
    def movement_cost(person); Float::INFINITY; end
    def thickness; 4; end
    def tiles_high; 2; end
  end

  class HighConcreteWallWindow < self
    def blocks_sight?(person); false; end
    def movement_cost(person); Float::INFINITY; end
    def spritesheet_pos; [[1, 1], [2, 1]]; end
    def minimap_color; Color.rgb(150, 150, 150); end
    def thickness; 4; end
    def tiles_high; 2; end
  end

  class LowBrickWall < self
    def blocks_sight?(person); false; end
    def spritesheet_pos; [[4, 0], [3, 0]]; end
    def minimap_color; Color.rgb(150, 150, 150); end
    def thickness; 2; end
    def movement_cost(person); 2; end
    def tiles_high; 1; end
  end

  class LowFence < self
    def blocks_sight?(person); false; end
    def spritesheet_pos; [[4, 1], [3, 1]]; end
    def minimap_color; Color.rgb(150, 150, 150); end
    def thickness; 0; end
    def movement_cost(person); 2; end
    def tiles_high; 1; end
  end
  
  WIDTH, HEIGHT = 32, 64
    
  attr_reader :objects, :grid_x, :grid_y, :cost, :occlusions

  def blocks_sight?(person); true; end
  def blocks_movement?(person); movement_cost(person) == Float::INFINITY; end
  def allows_movement?(person); movement_cost(person) < Float::INFINITY; end

  def thickness; 0; end

  def zorder; super + 0.01; end
  def to_s; "<#{self.class.name} #{@tiles[0].grid_position} <=> #{@tiles[1].grid_position}]>"; end
  def occludes?; @occlusions > 0; end

  def initialize(map, data)
    @tiles = data[DATA_TILES].map {|p| map.tile_at_grid(*p) }.sort_by(&:y)

    @@sprites ||= SpriteSheet.new("walls.png", WIDTH, HEIGHT, 8)

    options = {
        rotation_center: :bottom_center,
        x: @tiles.first.x,
        y: @tiles.first.y + (HEIGHT / 8) + 1,
        zorder: @tiles.first.y + 0.01,
    }

    @cost = options[:cost]
    @objects = []
    @occlusions = 0 # Number of objects occluded by the wall.

    super(options)

    if @tiles.last.grid_y > @tiles.first.grid_y
      @tiles.last.add_wall :up, self
      @tiles.first.add_wall :down, self
      @image = spritesheet_pos ? @@sprites[*spritesheet_pos[SPRITESHEET_VERTICAL]] : nil
      @x += 2
    else
      @tiles.last.add_wall :right, self
      @tiles.first.add_wall :left, self
      @image = spritesheet_pos ? @@sprites[*spritesheet_pos[SPRITESHEET_HORIZONTAL]] : nil
      @x -= 2
    end

    map << self
  end

  def occlusions=(value)
    @occlusions = value

    raise if @occlusions < 0

    @occlusions
  end

  def destination(from, person)
    blocks_movement?(person) ? nil : (@tiles - [from]).first
  end

  def draw
    if @image
      color = occludes? ? SEMI_TRANSPARENT_COLOR : OPAQUE_COLOR
      @image.draw_rot @x, @y, @zorder, 0, 0.5, 1, 1, 1, color
    end
  end

  def to_json(*a)
    {
        DATA_TYPE => Inflector.demodulize(self.class.name),
        DATA_TILES => @tiles.map(&:grid_position),
    }.to_json(*a)
  end
end