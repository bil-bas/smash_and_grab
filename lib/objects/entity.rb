require 'set'
require_relative "../path"

class Entity < StaticObject
  extend Forwardable

  DATA_TYPE = 'type'
  DATA_TILE = 'tile'
  DATA_MOVEMENT_POINTS = 'movement_points'
  DATA_ACTION_POINTS = 'action_points'
  DATA_HEALTH = 'health'
  DATA_FACING = 'facing'
  MELEE_COST = 2
  MELEE_DAMAGE = 5

  def_delegators :@faction, :minimap_color, :active?, :inactive?

  attr_reader :faction, :movement_points, :action_points, :health

  alias_method :mp, :movement_points
  alias_method :ap, :action_points

  def to_s; "<#{self.class.name}##{@type} #{grid_position}>"; end
  def name; @type.split("_").map(&:capitalize).join(" "); end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/entities.yml", EXTRACT_PATH)); end
  def self.types; config.keys; end

  def initialize(map, data)
    @type = data['type']
    config = self.class.config[data['type']]

    @@sprites ||= SpriteSheet.new("characters.png", 64 + 2, 64 + 2, 8)

    options = {
        image: @@sprites[*config['spritesheet_position']],
        factor_x: data[DATA_FACING] == 'right' ? 1 : -1,
    }

    super(map.tile_at_grid(*data[DATA_TILE]), options)

    raise @type unless @image


    @max_movement_points = config['movement_points']
    @movement_points = data[DATA_MOVEMENT_POINTS] || @max_movement_points

    @max_action_points = config['action_points']
    @action_points = data[DATA_ACTION_POINTS] || @max_action_points

    @max_health = config['health']
    @health = data[DATA_HEALTH] || @max_health

    @faction = map.send(config['faction'])

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
    @movement_points = @max_movement_points
    @action_points = @max_action_points
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

      tile = wall.destination(starting_tile)
      unless tiles.include? tile
        path = path_to(tile)

        if path.accessible? and @movement_points >= path.move_distance
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
    return NoPath.new if destination_tile == tile
    return InaccessiblePath.new(destination_tile) unless destination_tile.passable?(self)

    closed_tiles = Set.new # Tiles we've already dealt with.
    open_paths = { tile => PathStart.new(tile, destination_tile) } # Paths to check { tile => path_to_tile }.

    while open_paths.any?
      # Check the (expected) shortest path and move it to closed, since we have considered it.
      path = open_paths.each_value.min_by(&:cost)
      current_tile = path.last

      open_paths.delete current_tile
      closed_tiles << current_tile

      next if path.is_a? MeleePath

      # Check adjacent tiles.
      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile)

        new_path = nil

        if entity = testing_tile.entity and enemy?(entity)
          # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
          if (current_tile.empty? or current_tile == tile) and ap >= MELEE_COST
            new_path = MeleePath.new(path, testing_tile)
          else
            next
          end
        elsif testing_tile.passable?(self)
          new_path = MovePath.new(path, testing_tile, wall.movement_cost)
        end

        return InaccessiblePath.new(destination_tile) if new_path.nil?
        return new_path if testing_tile == destination_tile

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

    InaccessiblePath.new(destination_tile) # Failed to connect at all.
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
        DATA_TYPE => @type,
        DATA_TILE => grid_position,
        DATA_HEALTH => @health,
        DATA_MOVEMENT_POINTS => @movement_points,
        DATA_ACTION_POINTS => @action_points,
        DATA_FACING => factor_x > 0 ? :right : :left,
    }.to_json(*a)
  end
end