class Wall < GameObject
  SEMI_TRANSPARENT_COLOR = Color.rgba(255, 255, 255, 120)
  OPAQUE_COLOR = Color::WHITE

  DATA_TYPE = 'type'
  DATA_TILES = 'tiles'
  
  SPRITE_WIDTH, SPRITE_HEIGHT = 32, 64
    
  attr_reader :occlusions, :minimap_color, :tiles_high, :thickness, :movement_cost, :type, :tiles

  def blocks_movement?; movement_cost == Float::INFINITY; end
  def allows_movement?; movement_cost < Float::INFINITY; end

  def zorder; super + 0.01; end
  def to_s; "<#{self.class.name}##{@type} #{@tiles[0].grid_position} <=> #{@tiles[1].grid_position}]>"; end
  def occludes?; @occlusions > 0; end

  def blocks_sight?; @blocks_sight; end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/walls.yml", EXTRACT_PATH)); end
  def self.sprites; @@sprites ||= SpriteSheet.new("walls.png", SPRITE_WIDTH, SPRITE_HEIGHT, 8); end

  def initialize(map, data)
    options = {
        rotation_center: :bottom_center,
    }

    super(options)

    @objects = []
    @occlusions = 0 # Number of objects occluded by the wall.

    @map = map

    @tiles = data[DATA_TILES].map {|p| map.tile_at_grid(*p) }.sort_by(&:y)

    self.type = data[DATA_TYPE]

    @destinations = {
        @tiles.first => @tiles.last,
        @tiles.last => @tiles.first,
    }

    self.x, self.y = @tiles.first.x, @tiles.first.y + (SPRITE_HEIGHT / 8) + 1,
    self.zorder = @tiles.first.y + 0.01

    if @tiles.last.grid_y > @tiles.first.grid_y
      @tiles.last.add_wall :up, self
      @tiles.first.add_wall :down, self
      @x += 2
    else
      @tiles.last.add_wall :right, self
      @tiles.first.add_wall :left, self
      @x -= 2
    end
  end

  def type=(type)
    changed = defined? @type

    @type = type

    config = self.class.config[@type]

    @minimap_color = Color.rgba(*config['minimap_color'])
    @blocks_sight = config['blocks_sight']
    @movement_cost = config['movement_cost']
    @tiles_high = config['tiles_high']
    @thickness = config['thickness']

    @map.remove self if @image

    spritesheet_positions = config['spritesheet_positions']
    if @tiles.last.grid_y > @tiles.first.grid_y
      @image = spritesheet_positions ? self.class.sprites[*spritesheet_positions['vertical']] : nil
    else
      @image = spritesheet_positions ? self.class.sprites[*spritesheet_positions['horizontal']] : nil
    end

    @map << self if @image

    @map.publish :wall_type_changed, self if changed

    type
  end

  def occlusions=(value)
    @occlusions = value

    raise if @occlusions < 0

    @color = occludes? ? SEMI_TRANSPARENT_COLOR : OPAQUE_COLOR

    @occlusions
  end

  def destination(from)
    blocks_movement? ? nil : @destinations[from]
  end

  def draw
    @image.draw_rot @x, @y, @zorder, 0, 0.5, 1, 1, 1, @color
  end

  def to_json(*a)
    {
        DATA_TYPE => @type,
        DATA_TILES => @tiles.map(&:grid_position),
    }.to_json(*a)
  end
end