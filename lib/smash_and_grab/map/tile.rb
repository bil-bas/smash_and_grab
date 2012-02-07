module SmashAndGrab
class Tile < GameObject
  include Fidgit::Event

  WIDTH, HEIGHT = 32, 16

  # x, y, direction to cause occlusion.
  WALL_OCCLUSION_POSITIONS = [
      [[ 0,  0], :left],
      [[ 0,  0], :down],
      [[-1,  1], :right],
      [[-1,  1], :up],

      [[-1,  1], :left,],
      [[-1,  1], :down],
      [[-2,  2], :up],
      [[-2,  2], :right],
  ]

  attr_reader :object, :grid_x, :grid_y, :movement_cost, :map, :minimap_color, :type

  def empty?; @object.nil?; end
  def to_s; "<#{self.class.name}##{@type} #{grid_position}>"; end
  def grid_position; [@grid_x, @grid_y]; end
  def position; [@x, @y]; end
  def needs_to_be_seen?; (@temp_occlusions > 0) or @object; end # Causes walls to become transparent.
  def blocks_sight?; @type == 'none' or (@object and @object.blocks_sight?); end
  def zoc?(faction); entities_exerting_zoc(faction).any?; end

  # Blank white tile, useful for colourising tiles.
  class << self
    def blank; @sprites[0]; end
    def config; @config ||= YAML.load_file(File.expand_path("config/map/tiles.yml", EXTRACT_PATH)); end
    def sprites; @sprites ||= SpriteSheet["floor_tiles.png", WIDTH, HEIGHT, 4]; end
  end

  attr_reader :entities_exerting_zoc

  def initialize(type, map, grid_x, grid_y)
    @map, @grid_x, @grid_y = map, grid_x, grid_y

    super(x: (@grid_y + @grid_x) * WIDTH / 2, y: (@grid_y - @grid_x) * HEIGHT / 2)

    self.type = type
    self.zorder = @y

    @object = nil
    @walls = {}

    @temp_occlusions = 0

    @entities_exerting_zoc = Set.new
  end

  def entities_exerting_zoc(faction)
    @entities_exerting_zoc.select {|e| e.action? and e.faction.enemy? faction }
  end

  def add_zoc(entity)
    @entities_exerting_zoc << entity
  end

  def remove_zoc(entity)
    @entities_exerting_zoc.delete entity
  end

  def type=(type)
    changed = defined? @type

    raise unless type.is_a? Symbol
    @type = type

    config = self.class.config[@type]

    @minimap_color = Color.rgb(*config[:minimap_color])
    @movement_cost = config[:movement_cost]
    @image = if config.has_key? :spritesheet_position
      self.class.sprites[*config[:spritesheet_position]]
    else
      nil
    end

    @map.publish :tile_type_changed, self if changed

    type
  end

  def passable?(person)
    movement_cost < Float::INFINITY
  end

  def end_turn_on?(person)
    passable?(person) and @object.end_turn_on?(person)
  end

  # List of squares that can be entered from this tile.
  def exits(person)
    walls = @walls.values.delete_if {|w| w.blocks_movement? }
    walls.select {|w| w.allows_movement? and w.destination(self).passable?(person) }
  end

  # Should only be called from the object itself.
  def add(object)
    raise "Can't add null object" if object.nil?
    raise "Tile already has an object, so can't add object #{object.inspect}" unless @object.nil?

    @object = object

    update_wall_occlusions
    map.publish :tile_contents_changed, self

    if object.exerts_zoc?
      adjacent_tiles(object).each {|t| t.add_zoc object }
    end

    object
  end
  alias_method :<<, :add

  # Should only be called from the object itself.
  def remove(object)
    raise "Can't remove object #{object.inspect}" unless object == @object

    @object = nil

    update_wall_occlusions
    map.publish :tile_contents_changed, self

    if object.exerts_zoc?
      adjacent_tiles(object).each {|t| t.remove_zoc object }
    end

    object
  end

  def modify_occlusions(value)
    @temp_occlusions += value
    raise if @temp_occlusions < 0
    update_wall_occlusions
    @temp_occlusions
  end

  # Update all nearby walls, to allow them to check if they occlude (or don't occlude) this tile.
  def update_wall_occlusions
    unless defined? @walls_occluded_by
      @walls_occluded_by = []

      WALL_OCCLUSION_POSITIONS.each do |(offset_x, offset_y), direction|
        if tile = @map.tile_at_grid(grid_x + offset_x, grid_y + offset_y)
          wall = tile.wall(direction)
          @walls_occluded_by << wall if wall
        end
      end
    end

    @walls_occluded_by.each(&:update_occlusion)
  end

  def adjacent_tiles(entity)
    exits(entity).map {|wall| wall.destination(self) }
  end

  def add_wall(direction, wall)
    raise "Bad direction #{direction}" unless [:left, :right, :up, :down].include? direction
    @walls[direction] = wall
  end

  # Returns wall in this direction.
  # @return [Wall]
  def wall(direction)
    @walls[direction]
  end

  # @return [Wall] wall between this and other tile.
  def wall_to(tile)
    @walls[direction_to tile]
  end

  # @return [Symbol] Direction to another tile
  def direction_to(tile)
    @walls.each_pair do |direction, wall|
      return direction if wall.destination(self) == tile
    end

    nil
  end

  def to_json(*a)
    @type.to_json(*a)
  end
end
end