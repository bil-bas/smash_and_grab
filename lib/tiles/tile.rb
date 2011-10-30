class Tile < GameObject
  class Grass < Tile
    def cost; 2; end
    def spritesheet_pos; [1, 0]; end
    def minimap_color; Color.rgb(0, 200, 0); end
  end
  
  class Concrete < Tile
    def spritesheet_pos; [2, 0]; end
    def minimap_color; Color.rgb(200, 200, 200); end
  end

  class Lava < Tile
    def cost; Float::INFINITY; end
    def spritesheet_pos; [3, 0]; end
    def minimap_color; Color.rgb(255, 200, 0); end
  end
  
  WIDTH, HEIGHT = 32, 16

  WALL_OCCLUSION_POSITIONS = [
      [[0, 0], :left],
      [[0, 0], :bottom],
      [[-1, 1], :left],
      [[-1, 1], :right],
      [[-1, 1], :top],
      [[-1, 1], :bottom],
      [[-2, 2], :top],
      [[-2, 2], :right],
  ]

  attr_reader :objects, :grid_x, :grid_y, :cost

  def map; parent.map; end
  def empty?; @objects.empty?; end
  def to_s; "<#{self.class.name} [#{grid_x}, #{grid_y}]>"; end

  # Blank white tile, useful for colourising tiles.
  def self.blank; @@sprites[0]; end
  
  def initialize(map, grid_x, grid_y, options = {})
    @map, @grid_x, @grid_y = map, grid_x, grid_y

    unless defined? @@sprites
      @@sprites = SpriteSheet.new("floor_tiles.png", WIDTH, HEIGHT, 8)
    end

    options = {
        image: @@sprites[*spritesheet_pos],
        x: (@grid_y + @grid_x) * WIDTH / 2,
        y: (@grid_y - @grid_x) * HEIGHT / 2,
        rotation_center: :center_center,
        zorder: options[:y],
    }.merge! options

    super(options)

    @cost = 1
    @objects = []
    @walls = {}
  end

  def passable?(person)
    cost < Float::INFINITY and objects.all? {|o| o.passable? person }
  end

  def end_turn_on?(person)
    passable?(person) and @objects.all? {|o| o.end_turn_on?(person) }
  end

  # List of squares that can be entered from this tile.
  def adjacent_passable(person)
    walls = @walls.values.delete_if {|w| w.blocks_movement?(person) }
    tiles = walls.map {|w| w.destination(self, person) }
    tiles.select {|t| t.passable?(person) }
  end

  def add_object(object)
    raise "can't re-add object" if @objects.include? object

    @objects << object
    object.x, object.y = [x, y]

    modify_occlusions +1

    object
  end

  def remove_object(object)
    raise "can't remove object" unless @objects.include? object

    @objects.delete object

    modify_occlusions -1

    object
  end

  def modify_occlusions(value)
    WALL_OCCLUSION_POSITIONS.each do |(offset_x, offset_y), direction|
      if tile = @map.tile_at_grid(grid_x + offset_x, grid_y + offset_y)
        if wall = tile.wall(direction)
          wall.occlusions += value
        end
      end
    end
  end

  def minimap_color
    # Todo: Passable to local player.
    if empty?
      Color.rgb(200, 200, 200)
    else
      Color.rgb(50, 50, 50)
    end
  end

  def add_wall(direction, wall)
    raise "Bad direction #{direction}" unless [:left, :right, :top, :bottom].include? direction
    @walls[direction] = wall
  end

  def wall(direction)
    @walls[direction]
  end

  def to_json(*a)
    Inflector.demodulize(self.class.name).to_json(*a)
  end
end