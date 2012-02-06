require 'set'
require 'fiber'

require_relative "../path"
require_relative "../abilities"
require_relative "world_object"
require_relative "floating_text"

module SmashAndGrab
module Objects
class Entity < WorldObject
  extend Forwardable

  CLASS = :entity

  SPRITE_WIDTH, SPRITE_HEIGHT = 66, 66
  PORTRAIT_WIDTH, PORTRAIT_HEIGHT = 36, 36

  STATS_BACKGROUND_COLOR = Color::BLACK
  STATS_HP_COLOR = Color.rgb(0, 200, 0)
  STATS_MP_COLOR = Color.rgb(100, 100, 255)
  STATS_AP_COLOR = Color::YELLOW
  STATS_USED_COLOR = Color.rgb(100, 100, 100)
  STATS_WIDTH = 12.0
  STATS_HALF_WIDTH = STATS_WIDTH / 2

  ACTOR_NAME_COLOR = Color.rgb(50, 200, 50)
  TARGET_NAME_COLOR = Color.rgb(50, 200, 50)
  DAMAGE_NUMBER_COLOR = Color::RED

  class << self
    def config; @config ||= YAML.load_file(File.expand_path("config/map/entities.yml", EXTRACT_PATH)); end
    def types; config.keys; end
    def sprites; @sprites ||= SpriteSheet.new("entities.png", SPRITE_WIDTH, SPRITE_HEIGHT, 8); end
    def portraits; @portraits ||= SpriteSheet.new("entity_portraits.png", PORTRAIT_WIDTH, PORTRAIT_HEIGHT, 8); end
  end

  event :ended_turn
  event :started_turn

  def_delegators :@faction, :minimap_color, :active?, :inactive?

  attr_reader :faction, :movement_points, :action_points, :health, :type, :portrait,
              :max_movement_points, :max_action_points, :max_health

  alias_method :hp, :health
  alias_method :max_hp, :max_health

  def movement_points=(movement_points)
    @movement_points = movement_points
    publish :changed
    @movement_points
  end

  def action_points=(action_points)
    @action_points = action_points
    publish :changed
    @action_points
  end

  alias_method :max_mp, :max_movement_points
  alias_method :max_ap, :max_action_points

  alias_method :mp, :movement_points
  alias_method :ap, :action_points

  alias_method :mp=, :movement_points=
  alias_method :ap=, :action_points=

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def alive?; @health > 0 and @tile; end
  def title; t.title; end
  def colorized_name; faction.class::TEXT_COLOR.colorize name; end

  def initialize(map, data)
    @type = data[:type]
    config = self.class.config[data[:type]]

    @faction = map.send(config[:faction])

    options = {
        image: self.class.sprites[*config[:spritesheet_position]],
        factor_x: data[:facing].to_sym == :right ? 1 : -1,
    }

    @portrait = self.class.portraits[*config[:spritesheet_position]]

    super(map, data, options)

    raise @type unless image

    @max_movement_points = config[:movement_points]
    @movement_points = data[:movement_points] || @max_movement_points

    @max_action_points = config[:action_points]
    @action_points = data[:action_points] || @max_action_points

    @max_health = config[:health]
    @health = data[:health] || @max_health

    # Load other abilities of the entity from config.
    @abilities = {}

    # Everyone who has movement_points has the ability to move, without it needing to be explicit.
    @abilities[:move] = Abilities.ability(self, type: :move) if max_movement_points > 0

    if config[:abilities]
      config[:abilities].each do |ability_data|
        @abilities[ability_data[:type]] = Abilities.ability(self, ability_data)
      end
    end

    @queued_activities = []

    @faction << self

    @stat_bars_record = nil
    subscribe :changed do
      @stat_bars_record = nil
    end
  end

  def has_ability?(type); @abilities.has_key? type; end
  def ability(type); @abilities[type]; end

  def health=(value)
    original_health = @health
    @health = [value, 0].max

    # Show damage/healing as a floating number.
    if original_health != @health
      text, color = if @health > original_health
                      ["+#{@health - original_health}", Color::GREEN]
                    else
                      [(@health - original_health).to_s, Color::RED]
                    end

      FloatingText.new(text, color: color, x: x, y: y - height / 3, zorder: y - 0.01)
      publish :changed
    end

    if @health == 0 and @tile
      parent.publish :game_info, "#{colorized_name} was vanquished!"
      self.tile = nil
      @queued_activities.empty?
    end

    @health
  end
  alias_method :hp=, :health=

  # Called from GameAction::Ability
  # Also used to un-melee :)
  def make_melee_attack(target, damage)
    add_activity do
      if damage > 0 # do => wound
        face target
        self.z += 10
        delay 0.1
        self.z -= 10

        # Can be dead at this point if there were 2-3 attackers of opportunity!
        if target.alive?
          parent.publish :game_info, "#{colorized_name} smashed #{target.colorized_name} for {#{DAMAGE_NUMBER_COLOR.colorize damage}}"
          target.health -= damage

          target.color = Color.rgb(255, 100, 100)
          delay 0.1
          target.color = Color::WHITE
        else
          parent.publish :game_info, "#{colorized_name} kicked #{target.colorized_name} while they were down"
        end
      else # undo => heal
        target.color = Color.rgb(255, 100, 100)
        delay 0.1
        target.health -= damage
        target.color = Color::WHITE

        self.z += 10
        delay 0.1
        self.z -= 10
      end
    end
  end

  def make_ranged_attack(target, damage)
    add_activity do
      if damage > 0 # do => wound
        face target

        # Can be dead at this point if there were 2-3 attackers of opportunity!
        if target.alive?
          parent.publish :game_info, "#{colorized_name} shot #{target.colorized_name} for {#{DAMAGE_NUMBER_COLOR.colorize damage}}"
          target.health -= damage

          target.color = Color.rgb(255, 100, 100)
          delay 0.1
          target.color = Color::WHITE
        else
          parent.publish :game_info, "#{colorized_name} shot #{target.colorized_name} while they were down"
        end
      else # undo => heal
        target.color = Color.rgb(255, 100, 100)
        delay 0.1
        target.health -= damage
        target.color = Color::WHITE
      end
    end
  end

  def start_turn
    self.movement_points = @max_movement_points
    self.action_points = @max_action_points
    publish :started_turn
  end

  def end_turn
    publish :ended_turn
  end

  def draw
    return unless alive?

    super()

    draw_stat_bars @y
  end

  def draw_stat_bars(zorder)
    @stat_bars_record ||= $window.record 1, 1 do
      # Draw background shadow.
      height = 1
      height += 1 if active?
      height += 1 if max_ap > 0

      $window.pixel.draw -0.5, -0.5, 0, STATS_WIDTH + 1, height + 1, STATS_BACKGROUND_COLOR

      # Health.
      $window.pixel.draw 0, 0, 0, STATS_WIDTH * health / max_health, 1, STATS_HP_COLOR

      # Action points.
      if max_ap > 0
        pip_width = (STATS_WIDTH + 1 - max_ap) / max_ap
        max_ap.times do |i|
          color = i < ap ? STATS_AP_COLOR : STATS_USED_COLOR
          $window.pixel.draw i * pip_width + i, 1, 0, pip_width, 1, color
        end
      end

      # Movement points.
      $window.pixel.draw 0, 2, 0, 12.0 * mp / max_mp, 1, STATS_MP_COLOR if active?
    end

    @stat_bars_record.draw @x - STATS_HALF_WIDTH, @y - 4, zorder
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
    open_paths = { destination_tile => Paths::Start.new(destination_tile, destination_tile) }

    melee_cost = has_ability?(:melee) ? ability(:melee).action_cost : Float::INFINITY

    while open_paths.any?
      path = open_paths.each_value.min_by(&:cost)
      current_tile = path.last

      open_paths.delete current_tile
      closed_tiles << current_tile

      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile)
        object = testing_tile.object

        if object and object.is_a?(Objects::Entity) and enemy?(object)
          # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
          if (current_tile.empty? or current_tile == tile) and ap >= melee_cost
            valid_tiles << testing_tile
          end

        elsif testing_tile.passable?(self) and (object.nil? or object.passable?(self))
          new_path = Paths::Move.new(path, testing_tile, wall.movement_cost)

          # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
          if new_path.move_distance <= movement_points
            old_path = open_paths[testing_tile]
            if old_path
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
    return Paths::None.new if destination_tile == tile
    return Paths::Inaccessible.new(destination_tile) unless destination_tile.passable?(self)

    closed_tiles = Set.new # Tiles we've already dealt with.
    open_paths = { tile => Paths::Start.new(tile, destination_tile) } # Paths to check { tile => path_to_tile }.

    destination_object =  destination_tile.object
    destination_is_enemy = (destination_object and destination_object.is_a? Entity and destination_object.enemy?(self))

    melee_cost = has_ability?(:melee) ? ability(:melee).action_cost : Float::INFINITY

    while open_paths.any?
      # Check the (expected) shortest path and move it to closed, since we have considered it.
      path = open_paths.each_value.min_by(&:cost)
      current_tile = path.last

      return path if current_tile == destination_tile

      open_paths.delete current_tile
      closed_tiles << current_tile

      next if path.is_a? Paths::Melee

      # Check adjacent tiles.
      exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
      exits.each do |wall|
        testing_tile = wall.destination(current_tile)

        new_path = nil

        object = testing_tile.object
        if testing_tile.zoc?(faction) and not (testing_tile == destination_tile or destination_is_enemy)
          # Avoid tiles that have zoc, unless at the end of the path. You have to MANUALLY enter.
          next
        elsif object and object.is_a?(Objects::Entity) and enemy?(object)
          # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
          if (current_tile.empty? or current_tile == tile) and ap >= melee_cost
            new_path = Paths::Melee.new(path, testing_tile)
          else
            next
          end
        elsif testing_tile.passable?(self)
          if object.nil? or object.passable?(self)
            new_path = Paths::Move.new(path, testing_tile, wall.movement_cost)
          else
            next
          end
        end

        # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
        old_path = open_paths[testing_tile]
        if old_path
          if new_path.move_distance < old_path.move_distance
            open_paths[testing_tile] = new_path
          end
        else
          open_paths[testing_tile] = new_path
        end
      end
    end

    Paths::Inaccessible.new(destination_tile) # Failed to connect at all.
  end

  def update
    super

    unless @queued_activities.empty?
      @queued_activities.first.resume if @queued_activities.first.alive?
      unless @queued_activities.first.alive?
        @queued_activities.shift
        publish :changed if @queued_activities.empty?
      end
    end
  end

  def add_activity(&action)
    @queued_activities << Fiber.new(&action)
    publish :changed if @queued_activities.size == 1 # Means busy? changed from false to true.
  end

  def prepend_activity(&action)
    @queued_activities.unshift Fiber.new(&action)
    publish :changed if @queued_activities.size == 1 # Means busy? changed from false to true.
  end

  def clear_activities
    had_activities = @queued_activities.any?
    @queued_activities.clear
    publish :changed if had_activities # Means busy? changed from true to false.
  end

  def busy?
    @queued_activities.any?
  end

  # @overload delay(duration)
  #   Wait for duration (Called from an activity ONLY!)
  #   @param duration [Number]
  #
  # @overload delay
  #   Wait until next frame (Called from an activity ONLY!)
  def delay(duration = 0)
    raise if duration < 0

    if duration == 0
      Fiber.yield
    else
      finish = Time.now + duration
      Fiber.yield until Time.now >= finish
    end
  end

  # @param target [Tile, Objects::WorldObject]
  def face(target)
    change_in_x = target.x - x
    self.factor_x = change_in_x > 0 ? 1 : -1
  end

  # Actually perform movement (called from GameAction::Ability).
  def move(tiles, movement_cost)
    raise "Not enough movement points (#{self} tried to move #{movement_cost} with #{@movement_points} left #{tiles} )" unless movement_cost <= @movement_points

    tiles = tiles.map {|pos| @map.tile_at_grid *pos } unless tiles.first.is_a? Tile

    @movement_points -= movement_cost

    add_activity do
      tiles.each_cons(2) do |from, to|
        face to

        # TODO: this will be triggered _every_ time you move, even when redoing is done!
        trigger_zoc_melees from
        break unless alive?

        delay 0.1

        break unless alive?

        # Skip through a tile if we are moving through something else!
        if to.object
          self.z = 20
          self.x, self.y = to.x, to.y
        else
          self.tile = to
          self.z = 0
        end

        # TODO: this will be triggered _every_ time you move, even when redoing is done!
        trigger_overwatches to
        break unless alive?

        # TODO: this will be triggered _every_ time you move, even when redoing is done!
        trigger_zoc_melees to
        break unless alive?
      end
    end

    nil
  end

  def manhattan_distance(tile)
    (tile.grid_x - grid_x).abs + (tile.grid_y - grid_y).abs
  end

  # We have moved; let all our enemies shoot at us.
  def trigger_overwatches(tile)
    @map.factions.each do |faction|
      if faction.enemy? self.faction
        faction.entities.each do |enemy|
          if alive?
            enemy.attempt_overwatch self
            prepend_activity do
              delay while enemy.busy?
            end
          end
        end
      end
    end
  end

  # Someone has moved into our view and we get to shoot them...
  def attempt_overwatch(target)
    if alive? and use_ability?(:ranged)
      ranged = ability :ranged
      range = manhattan_distance(target.tile)
      if range.between?(ranged.min_range, ranged.max_range) and
         line_of_sight_blocked_by(target.tile).nil?

        parent.publish :game_info, "#{colorized_name} made a snap shot!"
        use_ability :ranged, target
      end
    end
  end

  # TODO: Need to think of the best way to trigger this. It should only happen once, when you actually "first" move.
  def trigger_zoc_melees(tile)
    entities = tile.entities_exerting_zoc(self)
    enemies = entities.find_all {|e| e.enemy? self }
    enemies.each do |enemy|
      if alive?
        enemy.attempt_zoc_melee self
        prepend_activity do
          delay while enemy.busy?
        end
      end
    end
  end

  # Someone has moved into, or out of, our ZoC.
  def attempt_zoc_melee(target)
    if alive? and use_ability?(:melee)
      parent.publish :game_info, "#{colorized_name} got an attack of opportunity!"
      use_ability :melee, target
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

  def use_ability(name, *args)
    raise "#{self} does not have ability: #{name.inspect}" unless has_ability? name
    map.actions.do :ability, ability(name).action_data(*args)
  end

  def use_ability?(name)
    alive? and has_ability?(name) and ap >= ability(name).action_cost
  end

  def to_json(*a)
    data = {
        :class => CLASS,
        type: @type,
        id: id,
        health: @health,
        movement_points: @movement_points,
        action_points: @action_points,
        facing: factor_x > 0 ? :right : :left,
    }

    data[:tile] = grid_position if @tile

    data.to_json(*a)
  end
end
end
end
