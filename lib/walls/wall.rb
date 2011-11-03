class Wall < GameObject
  SEMI_TRANSPARENT_COLOR = Color.rgba(255, 255, 255, 120)
  OPAQUE_COLOR = Color::WHITE

  DATA_TYPE = 'type'
  DATA_TILES = 'tiles'
  
  SPRITE_WIDTH, SPRITE_HEIGHT = 32, 64
    
  attr_reader :occlusions, :minimap_color, :tiles_high, :thickness, :movement_cost

  def blocks_movement?; movement_cost == Float::INFINITY; end
  def allows_movement?; movement_cost < Float::INFINITY; end

  def zorder; super + 0.01; end
  def to_s; "<#{self.class.name} #{@tiles[0].grid_position} <=> #{@tiles[1].grid_position}]>"; end
  def occludes?; @occlusions > 0; end

  def blocks_sight?; @blocks_sight; end

  def initialize(map, data)
    @@walls_config ||= YAML.load_file(File.expand_path("config/walls.yml", EXTRACT_PATH))
    @@sprites ||= SpriteSheet.new("walls.png", SPRITE_WIDTH, SPRITE_HEIGHT, 8)

    @type = data[DATA_TYPE]
    @config = @@walls_config[@type]

    @minimap_color = Color.rgba(*@config['minimap_color'])
    @blocks_sight = @config['blocks_sight']
    @movement_cost = @config['movement_cost']
    @tiles_high = @config['tiles_high']
    @thickness = @config['thickness']

    @tiles = data[DATA_TILES].map {|p| map.tile_at_grid(*p) }.sort_by(&:y)

    options = {
        rotation_center: :bottom_center,
        x: @tiles.first.x,
        y: @tiles.first.y + (SPRITE_HEIGHT / 8) + 1,
        zorder: @tiles.first.y + 0.01,
    }

    @objects = []
    @occlusions = 0 # Number of objects occluded by the wall.

    super(options)

    spritesheet_positions = @config['spritesheet_positions']
    if @tiles.last.grid_y > @tiles.first.grid_y
      @tiles.last.add_wall :up, self
      @tiles.first.add_wall :down, self
      @image = spritesheet_positions ? @@sprites[*spritesheet_positions['vertical']] : nil
      @x += 2
    else
      @tiles.last.add_wall :right, self
      @tiles.first.add_wall :left, self
      @image = spritesheet_positions ? @@sprites[*spritesheet_positions['horizontal']] : nil
      @x -= 2
    end

    map << self if @image
  end

  def occlusions=(value)
    @occlusions = value

    raise if @occlusions < 0

    @occlusions
  end

  def destination(from)
    blocks_movement? ? nil : (@tiles - [from]).first
  end

  def draw
    if @image
      color = occludes? ? SEMI_TRANSPARENT_COLOR : OPAQUE_COLOR
      @image.draw_rot @x, @y, @zorder, 0, 0.5, 1, 1, 1, color
    end
  end

  def to_json(*a)
    {
        DATA_TYPE => @type,
        DATA_TILES => @tiles.map(&:grid_position),
    }.to_json(*a)
  end
end