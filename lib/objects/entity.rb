require 'set'
require_relative "../path"
require_relative "world_object"

class Entity < WorldObject
  extend Forwardable

  CLASS = 'entity'
  DATA_MOVEMENT_POINTS = 'movement_points'
  DATA_ACTION_POINTS = 'action_points'
  DATA_HEALTH = 'health'
  DATA_FACING = 'facing'

  SPRITE_WIDTH, SPRITE_HEIGHT = 66, 66
  PORTRAIT_WIDTH, PORTRAIT_HEIGHT = 36, 36

  MELEE_COST = 1
  MELEE_DAMAGE = 5

  def_delegators :@faction, :minimap_color, :active?, :inactive?

  attr_reader :faction, :movement_points, :action_points, :health, :type, :portrait,
              :max_movement_points, :max_action_points, :max_health

  attr_writer :movement_points, :action_points

  alias_method :max_mp, :max_movement_points
  alias_method :max_ap, :max_action_points

  alias_method :mp, :movement_points
  alias_method :ap, :action_points

  alias_method :mp=, :movement_points=
  alias_method :ap=, :action_points=

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def name; @type.split("_").map(&:capitalize).join(" "); end
  def alive?; @health > 0 and @tile; end

  def self.config; @@config ||= YAML.load_file(File.expand_path("config/map/entities.yml", EXTRACT_PATH)); end
  def self.types; config.keys; end
  def self.sprites; @@sprites ||= SpriteSheet.new("entities.png", SPRITE_WIDTH, SPRITE_HEIGHT, 8); end
  def self.portraits; @@portraits ||= SpriteSheet.new("entity_portraits.png", PORTRAIT_WIDTH, PORTRAIT_HEIGHT, 8); end

  def sprint?; @action_points >= @max_action_points; end
  def sprint_bonus; @max_movement_points / 2; end

  def initialize(map, data)
    @type = data['type']
    config = self.class.config[data['type']]

    @faction = map.send(config['faction'])

    options = {
        image: self.class.sprites[*config['spritesheet_position']],
        factor_x: data[DATA_FACING].to_sym == :right ? 1 : -1,
    }

    @portrait = self.class.portraits[*config['spritesheet_position']]

    super(map, data, options)

    raise @type unless @image

    @max_movement_points = config['movement_points']
    @movement_points = data[DATA_MOVEMENT_POINTS] || @max_movement_points

    @max_action_points = config['action_points']
    @action_points = data[DATA_ACTION_POINTS] || @max_action_points

    @max_health = config['health']
    @health = data[DATA_HEALTH] || @max_health

    @faction << self
  end

  def sprint
    raise unless sprint?

    @movement_points += sprint_bonus
    @action_points = 0
    self
  end

  def health=(value)
    @health = [value, 0].max
    if @health == 0 and @tile
      @tile.remove self
      @tile = nil
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

  def draw
    super() if alive?
  end

  def friend?(character); @faction.friend? character.faction; end
  def enemy?(character); @faction.enemy? character.faction; end

  def exerts_zoc?; true; end
  def action?; @action_points > 0; end
  def move?; @movement_points > 0; end
  def end_turn_on?(person); false; end
  def impassable?(character); enemy? character; end
  def passable?(character); friend? character; end

  def destroy
    @faction.remove self
    super
  end

  # Returns a list of tiles this entity could move to (including those they could melee at) [Set]
  def potential_moves
    destination_tile = tile # We are sort of working backwards here.

    # Tiles we've already dealt with.
    closed_tiles = Set.new
    # Tiles we've looked at and that are in-range.
    valid_tiles = Set.new
    # Paths to check { tile => path_to_tile }.
    open_paths = { destination_tile => PathStart.new(destination_tile, destination_tile) }

    while open_paths.any?
      path = open_paths.each_value.min_by(&:cost)
      current_tile = path.last

      open_paths.delete current_tile
      closed_tiles << current_tile

      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile)
        object = testing_tile.object

        if object and object.is_a?(Entity) and enemy?(object)
          # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
          if (current_tile.empty? or current_tile == tile) and ap >= MELEE_COST
            valid_tiles << testing_tile
          end

        elsif testing_tile.passable?(self) and (object.nil? or object.passable?(self))
          new_path = MovePath.new(path, testing_tile, wall.movement_cost)

          # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
          if new_path.move_distance <= movement_points
            if old_path = open_paths[testing_tile]
              if new_path.move_distance < old_path.move_distance
                open_paths[testing_tile] = new_path
              end
            else
              open_paths[testing_tile] = new_path
              valid_tiles << testing_tile if testing_tile.empty?
            end
          end
        end
      end
    end

    valid_tiles
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

      return path if current_tile == destination_tile

      open_paths.delete current_tile
      closed_tiles << current_tile

      next if path.is_a? MeleePath

      # Check adjacent tiles.
      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile)

        new_path = nil

        object = testing_tile.object
        if object and object.is_a?(Entity) and enemy?(object)
          # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
          if (current_tile.empty? or current_tile == tile) and ap >= MELEE_COST
            new_path = MeleePath.new(path, testing_tile)
          else
            next
          end
        elsif testing_tile.passable?(self)
          if (object.nil? or object.passable?(self))
            new_path = MovePath.new(path, testing_tile, wall.movement_cost)
          else
            next
          end
        end

        # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
        if old_path = open_paths[testing_tile]
          if new_path.move_distance < old_path.move_distance
            open_paths[testing_tile] = new_path
          end
        else
          open_paths[testing_tile] = new_path
        end
      end
    end

    InaccessiblePath.new(destination_tile) # Failed to connect at all.
  end

  # Actually perform movement (called from GameAction::Move).
  def move(tiles, movement_cost)
    raise "Not enough movement points (#{self} tried to move #{movement_cost} with #{@movement_points} left #{tiles} )" unless movement_cost <= @movement_points

    destination = tiles.last
    @movement_points -= movement_cost

    change_in_x = destination.x - tiles[-2].x

    # Turn based on movement.
    self.factor_x = change_in_x > 0 ? 1 : -1

    @tile.remove self

    destination << self
    @tile = destination
  end

  # TODO: Need to think of the best way to trigger this. It should only happen once, when you actually "first" move.
  def trigger_zoc_attacks
    enemies = tile.entities_exerting_zoc(self)
    enemies.each do |enemy|
      map.actions.do :melee, enemy, self # Only get one opportunity attack per enemy entering.
    end
  end

  #
  def line_of_sight?(tile)
    !line_of_sight_blocked_by(tile)
  end

  # Returns the tile that blocks sight, otherwise nil.
  # Implements 'Bresenham's line algorithm'
  def line_of_sight_blocked_by(target_tile)
    start_tile = tile

    # Check for the special case of looking diagonally.
    x1, y1 = tile.grid_x, tile.grid_y
    x2, y2 = target_tile.grid_x, target_tile.grid_y

    step_x = x1 < x2 ? 1 : -1
    step_y = y1 < y2 ? 1 : -1
    dx, dy = (x2 - x1).abs, (y2 - y1).abs

    if dx == dy
      # Special case of the diagonal line.
      (dx - 1).times do
        x1 += step_x
        y1 += step_y

        # If the centre tile is blocked, then we don't work.
        tile = @map.tile_at_grid(x1, y1)
        if tile.blocks_sight?
          #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::RED
          return tile
        else
          #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::BLUE
        end
      end
    else
      # General case, ray-trace.
      error = dx - dy

      # Ensure that all tiles are visited that the sight-line passes over,
      # not just those that create a "drawn" line.
      dx *= 2
      dy *= 2

      length = ((dx + dy + 1) / 2)

      (length - 1).times do
        # Note that this ignores the special case of error == 0
        if error > 0
          error -= dy
          x1 += step_x
        else
          error += dx
          y1 += step_y
        end

        tile = @map.tile_at_grid(x1, y1)
        if tile.blocks_sight?
          #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::RED
          return tile
        else
          #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::BLUE
        end
      end
    end

    nil # Didn't hit anything.
  end

  def to_json(*a)
    data = {
        DATA_CLASS => CLASS,
        DATA_TYPE => @type,
        DATA_ID => id,
        DATA_HEALTH => @health,
        DATA_MOVEMENT_POINTS => @movement_points,
        DATA_ACTION_POINTS => @action_points,
        DATA_FACING => factor_x > 0 ? :right : :left,
    }

    data[DATA_TILE] = grid_position if @tile

    data.to_json(*a)
  end
end