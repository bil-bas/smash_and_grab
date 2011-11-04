class Tile < GameObject
  include Fidgit::Event

  WIDTH, HEIGHT = 32, 16

  # x, y, direction, min height to cause occlusion.
  WALL_OCCLUSION_POSITIONS = [
      [[ 0,  0], :left,   1],
      [[ 0,  0], :down,   1],
      [[-1,  1], :right,  1],
      [[-1,  1], :up,     1],

      [[-1,  1], :left,   2],
      [[-1,  1], :down,   2],
      [[-2,  2], :up,     2],
      [[-2,  2], :right,  2],
  ]

  event :updated

  attr_reader :objects, :grid_x, :grid_y, :movement_cost, :map, :minimap_color

  def empty?; @objects.empty?; end
  def to_s; "<#{self.class.name}##{@type} #{grid_position}>"; end
  def grid_position; [@grid_x, @grid_y]; end

  # Blank white tile, useful for colourising tiles.
  def self.blank; @@sprites[0]; end
  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/tiles.yml", EXTRACT_PATH)); end
  def self.sprites; @@sprites ||= SpriteSheet.new("floor_tiles.png", WIDTH, HEIGHT, 8); end

  def initialize(type, map, grid_x, grid_y)
    @type, @map, @grid_x, @grid_y = type, map, grid_x, grid_y

    config = self.class.config[type]

    @minimap_color = config['minimap_color']
    @movement_cost = config['movement_cost']

    super(image: self.class.sprites[*config['spritesheet_position']],
          x: (@grid_y + @grid_x) * WIDTH / 2, y: (@grid_y - @grid_x) * HEIGHT / 2)

    self.zorder = @y

    @objects = []
    @walls = {}
  end

  def passable?(person)
    movement_cost < Float::INFINITY
  end

  def end_turn_on?(person)
    passable?(person) and @objects.all? {|o| o.end_turn_on?(person) }
  end

  def entity; @objects.find {|o| o.is_a? Entity }; end

  # List of squares that can be entered from this tile.
  def exits(person)
    walls = @walls.values.delete_if {|w| w.blocks_movement? }
    walls.select {|w| w.allows_movement? and w.destination(self).passable?(person) }
  end

  def <<(object)
    raise "can't re-add object" if @objects.include? object

    @objects << object
    object.x, object.y = [x, y]

    modify_occlusions +1

    map.publish :tile_updated, self

    object
  end

  def remove(object)
    raise "can't remove object" unless @objects.include? object

    @objects.delete object

    modify_occlusions -1

    map.publish :tile_updated, self

    object
  end

  def modify_occlusions(value)
    WALL_OCCLUSION_POSITIONS.each do |(offset_x, offset_y), direction, min_height|
      if tile = @map.tile_at_grid(grid_x + offset_x, grid_y + offset_y)
        if wall = tile.wall(direction) and wall.tiles_high >= min_height
          wall.occlusions += value
        end
      end
    end
  end

  def add_wall(direction, wall)
    raise "Bad direction #{direction}" unless [:left, :right, :up, :down].include? direction
    @walls[direction] = wall
  end

  def wall(direction)
    @walls[direction]
  end

  def direction_to(tile)
    @walls.each_pair do |direction, wall|
      return direction if wall.destination(self) == tile
    end

    return nil
  end

  def to_json(*a)
    @type.to_json(*a)
  end
end