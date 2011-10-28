class Tile < GameObject
  class Grass < Tile
    def cost; Float::INFINITY; end
    def spritesheet_pos; [1, 0]; end
  end
  
  class Concrete < Tile
    def spritesheet_pos; [2, 0]; end
  end
  
  WIDTH, HEIGHT = 32, 16
  ADJACENT_POSITIONS = [[-1, 0], [0, -1], [1, 0], [0, 1]]
  #ADJACENT_POSITIONS = [[-1, 0], [0, -1], [1, 0], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]]
    
  attr_reader :objects, :grid_x, :grid_y, :cost

  def map; parent.map; end
  def empty?; @objects.empty?; end
  def to_s; "<#{self.class.name} [#{grid_x}, #{grid_y}]>"; end

  # Blank white tile, useful for colourising tiles.
  def self.blank; @@sprites[0]; end
  
  def initialize(grid_x, grid_y, options = {})
    @grid_x, @grid_y = grid_x, grid_y

    unless defined? @@sprites
      @@sprites = SpriteSheet.new("floor_tiles.png", WIDTH, HEIGHT, 8)
    end
    options[:image] = @@sprites[*spritesheet_pos]
    options[:x] = (@grid_y + @grid_x) * WIDTH / 2
    options[:y] = (@grid_y - @grid_x) * HEIGHT / 2
    options[:rotation_center] = :center_center
    options[:zorder] = options[:y]

    @cost = 1

    @objects = []

    super(options)
  end

  def passable?(character)
    cost < Float::INFINITY and objects.all? {|o| o.passable? character }
  end

  # List of squares directly adjacent to the character that are potentially passable.
  def adjacent_passable(character)
    tiles = ADJACENT_POSITIONS.map do |offset_x, offset_y|
      map.tile_at_grid(grid_x + offset_x, grid_y + offset_y)
    end

    tiles.compact!

    tiles.select! {|tile| tile.passable?(character) }

    tiles
  end

  def add_object(object)
    raise "can't re-add object" if @objects.include? object

    @objects << object
    object.x, object.y = [x, y]

    object
  end

  def remove_object(object)
    raise "can't remove object" unless @objects.include? object

    @objects.delete object

    object
  end

  def minimap_color
    if empty?
      # Todo: Passable to local player.
      if passable?(nil)
        Color.rgb(200, 200, 200)
      else
        Color.rgb(50, 50, 50)
      end
    else
      objects.last.minimap_color
    end
  end
end