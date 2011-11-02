require 'set'

class Entity < StaticObject
  class Character < Entity; end

  # Abstract path class.
  class Path
    TILE_SIZE = 16
    attr_reader :cost, :move_distance, :current, :first, :previous_path, :destination_distance

    def tiles; @previous_path.tiles + [current]; end

    def initialize(previous_path, current, destination, extra_move_distance)
      @previous_path, @current = previous_path, current

      @move_distance = @previous_path.move_distance + extra_move_distance
      @first = @previous_path.first
      @destination_distance = @previous_path.destination_distance
      @cost = @move_distance + @destination_distance
    end
  end

  # A path consisting just of movement.
  class MovePath < Path
    def initialize(previous_path, current, destination, extra_move_distance)
      super(previous_path, current, destination, current.cost + extra_move_distance)
    end
  end

  # A path consisting of melee, possibly with some movement beforehand.
  class MeleePath < Path
    def attacker; @previous_path.current; end
    def defender; @current; end
    def requires_movement?; previous_path.is_a? MovePath; end
    def initialize(previous_path, current, destination)
      super(previous_path, current, destination, 0)
    end
  end

  class PathStart < Path
    attr_reader :tiles

    def cost; 0; end
    def move_distance; 0; end

    def initialize(tile, destination)
      @current = tile
      @tiles = [tile]
      @destination_distance = (@current.grid_x - destination.grid_x).abs + (@current.grid_y - destination.grid_y).abs
    end
  end

  # --------------------

  extend Forwardable

  DATA_TYPE = 'type'
  DATA_IMAGE_INDEX = 'image_index'
  DATA_TILE = 'tile'
  DATA_MOVEMENT_POINTS = 'movement_points'
  DATA_ACTION_POINTS = 'action_points'
  DATA_HEALTH = 'health'
  DATA_FACING = 'facing'
  MOVEMENT_POINTS_PER_TURN = 4
  ACTION_POINTS_PER_TURN = 4
  MELEE_COST = 2
  MELEE_DAMAGE = 5
  INITIAL_HEALTH = 10


  def_delegators :@faction, :minimap_color, :active?, :inactive?

  attr_reader :faction, :movement_points, :action_points, :health

  alias_method :mp, :movement_points
  alias_method :ap, :action_points

  def to_s; "<#{self.class.name} #{grid_position}>"; end

  def initialize(map, data)
    unless defined? @@sprites
      @@sprites = SpriteSheet.new("characters.png", 64 + 2, 64 + 2)
    end

    @image_index = data[DATA_IMAGE_INDEX]

    options = {
        image: @@sprites.each.to_a[@image_index],
        factor_x: data[DATA_FACING] == 'right' ? 1 : -1,
    }

    super(map.tile_at_grid(*data[DATA_TILE]), options)

    @movement_points = data[DATA_MOVEMENT_POINTS] || MOVEMENT_POINTS_PER_TURN
    @action_points = data[DATA_ACTION_POINTS] || ACTION_POINTS_PER_TURN
    @health = data[DATA_HEALTH] || INITIAL_HEALTH

    @faction = case @image_index
                 when 0..6, 11, 12, 13, 14, 16, 17, 18, 37, 40, 41, 42, 43
                   map.goodies
                 when 15, 19, 20, 23..30, 31, 32, 33, 34, 35, 36, 39
                   map.baddies
                 when 7, 8, 9, 10, 21, 22, 38
                   map.bystanders
                 else
                   raise @image_index
               end

    @faction << self
  end

  def health=(value)
    @health = [value, 0].max
    if @health == 0
      destroy
    end
  end

  def melee(other)
    other.health -= MELEE_DAMAGE
    @action_points -= MELEE_COST
  end

  def start_turn
    @movement_points = MOVEMENT_POINTS_PER_TURN
    @action_points = ACTION_POINTS_PER_TURN
  end

  def end_turn
    # Do something?
  end

  def friend?(character); @faction.friend? character.faction; end
  def enemy?(character); @faction.enemy? character.faction; end

  def move?; @movement_points > 0; end
  def end_turn_on?(person); false; end
  def impassable?(character); enemy? character; end
  def passable?(character); friend? character; end

  def destroy
    @faction.remove self
    super
  end

  def potential_moves(options = {})
    options = {
        starting_tile: tile,
        tiles: Set.new,
    }.merge! options

    starting_tile = options[:starting_tile]
    tiles = options[:tiles]

    starting_tile.exits(self).each do |wall|

      tile = wall.destination(starting_tile, self)
      unless tiles.include? tile
        path = path_to(tile)

        if path and @movement_points >= path.move_distance
          # Can move onto this square - calculate further paths if we can move through the square.
          tiles << tile
          if path.is_a?(MovePath) and mp > path.move_distance or ap > 0
            potential_moves(starting_tile: tile, tiles: tiles)
          end
        end
      end
    end

    tiles.reject {|t| t.entity and friend? t.entity }
  end

  # A* path-finding.
  def path_to(destination_tile)
    return nil unless destination_tile.passable? self
    return nil if destination_tile == tile

    closed_tiles = Set.new # Tiles we've already dealt with.
    open_paths = { tile => PathStart.new(tile, destination_tile) } # Paths to check { tile => path_to_tile }.

    while open_paths.any?
      # Check the (expected) shortest path and move it to closed, since we have considered it.
      path = open_paths.each_value.min_by(&:cost)
      current_tile = path.current

      open_paths.delete current_tile
      closed_tiles << current_tile

      next if path.is_a? MeleePath

      # Check adjacent tiles.
      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile, self) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile, self)

        new_path = nil


        if entity = testing_tile.entity and enemy?(entity)
          # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
          if (current_tile.empty? or current_tile == tile) and ap >= MELEE_COST
            new_path = MeleePath.new(path, testing_tile, destination_tile)
          else
            next
          end
        elsif testing_tile.passable?(self)
          new_path = MovePath.new(path, testing_tile, destination_tile, wall.movement_cost(self))
        end

        return new_path if new_path.nil? or testing_tile == destination_tile

        # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
        if old_path = open_paths[testing_tile]
          if new_path.move_distance < old_path.move_distance
            open_paths.delete old_path
            open_paths[testing_tile] = new_path
          end
        else
          open_paths[testing_tile] = new_path
        end
      end
    end

    nil # Failed to connect at all.
  end

  def move(tiles, movement_cost)
    raise "Not enough movement points (tried to move #{movement_cost} with #{@movement_points} left)" unless movement_cost <= @movement_points

    parent.mouse_selection.select nil

    destination = tiles.last
    @movement_points -= movement_cost

    change_in_x = destination.x - @tile.x

    # Turn based on movement.
    unless change_in_x == 0
      self.factor_x = change_in_x > 0 ? 1 : -1
    end

    @tile.remove self
    destination << self

    [@tile, destination].each {|t| parent.minimap.update_tile t }

    @tile = destination

    parent.mouse_selection.select self
  end

  def to_json(*a)
    {
        DATA_TYPE => Inflector.demodulize(self.class.name),
        DATA_IMAGE_INDEX => @image_index,
        DATA_TILE => grid_position,
        DATA_HEALTH => @health,
        DATA_MOVEMENT_POINTS => @movement_points,
        DATA_ACTION_POINTS => @action_points,
        DATA_FACING => factor_x > 0 ? :right : :left,
    }.to_json(*a)
  end
end