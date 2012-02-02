class Wall < GameObject
  SEMI_TRANSPARENT_COLOR = Color.rgba(255, 255, 255, 120)
  OPAQUE_COLOR = Color::WHITE
  
  SPRITE_WIDTH, SPRITE_HEIGHT = 32, 64

  # [[x_offset, _y_offset], direction, height needed to occlude
  WALL_OCCLUSION_POSITIONS = {
      vertical: [
          [[ 0,  0],  1], # Own tile.
          [[+1,  0],  1], # Right.
          [[+1, -1],  2], # Top right.
          [[+2, -1],  2],
      ],
      horizontal: [
          [[ 0,  0],  1], # Own tile.
          [[ 0, -1],  1], # Top.
          [[+1, -1],  2], # Top right.
          [[+1, -2],  2],
      ]
  }
    
  attr_reader :minimap_color, :tiles_high, :thickness, :movement_cost, :type, :tiles, :orientation

  def blocks_movement?; movement_cost == Float::INFINITY; end
  def allows_movement?; movement_cost < Float::INFINITY; end

  def zorder; super + 0.01; end
  def to_s; "<#{self.class.name}##{@type} #{@tiles[0].grid_position} <=> #{@tiles[1].grid_position}]>"; end
  def occludes?; @occludes; end

  def blocks_sight?; @blocks_sight; end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/walls.yml", EXTRACT_PATH)); end
  def self.sprites; @@sprites ||= SpriteSheet.new("walls.png", SPRITE_WIDTH, SPRITE_HEIGHT, 8); end

  def initialize(map, data)
    options = {
        rotation_center: :bottom_center,
    }

    super(options)

    @objects = []
    @occludes = false # Does the wall occlude anything that should be seen?

    @map = map

    @tiles = data[:tiles].map {|p| map.tile_at_grid(*p) }.sort_by(&:y)

    @destinations = {
        @tiles.first => @tiles.last,
        @tiles.last => @tiles.first,
    }

    self.x, self.y = @tiles.first.x, @tiles.first.y + (SPRITE_HEIGHT / 8),
    self.zorder = @tiles.first.y + 0.01

    if @tiles.last.grid_y > @tiles.first.grid_y
      @tiles.last.add_wall :up, self
      @tiles.first.add_wall :down, self
      @orientation = :vertical
    else
      @tiles.last.add_wall :right, self
      @tiles.first.add_wall :left, self
      @orientation = :horizontal
    end

    self.type = data[:type]
  end

  def type=(type)
    changed = defined? @type

    @type = type

    config = self.class.config[@type]

    @minimap_color = Color.rgba(*config[:minimap_color])
    @blocks_sight = config[:blocks_sight]
    @movement_cost = config[:movement_cost]
    @tiles_high = config[:tiles_high]

    #@y -= (4 - @thickness) / 2 if @thickness
    @thickness = config[:thickness]
    #@y += (4 - @thickness) / 2 if @thickness

    spritesheet_positions = config[:spritesheet_positions]
    image = if @tiles.last.grid_y > @tiles.first.grid_y
      spritesheet_positions ? self.class.sprites[*spritesheet_positions[:vertical]] : nil
    else
      spritesheet_positions ? self.class.sprites[*spritesheet_positions[:horizontal]] : nil
    end

    @map.remove self if @image
    @image = image
    @map << self if @image

    @map.publish :wall_type_changed, self if changed

    update_occlusion

    type
  end

  # Recalculate possible occlusions from permanent objects.
  def update_occlusion
    grid_x, grid_y = tiles.first.grid_position

    # Look at all positions that could
    @occludes = WALL_OCCLUSION_POSITIONS[@orientation].any? do |(offset_x, offset_y), min_height|
      if @tiles_high >= min_height
        tile = @map.tile_at_grid(grid_x + offset_x, grid_y + offset_y)
        tile and tile.needs_to_be_seen?
      else
        false
      end
    end

    @color = occludes? ? SEMI_TRANSPARENT_COLOR : OPAQUE_COLOR
  end

  def destination(from)
    blocks_movement? ? nil : @destinations[from]
  end

  def draw
    @image.draw_rot @x, @y, @zorder, 0, 0.5, 1, 1, 1, @color
  end

  def to_json(*a)
    {
        type: @type,
        tiles: @tiles.map(&:grid_position),
    }.to_json(*a)
  end
end