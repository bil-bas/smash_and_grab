require 'set'
require 'fiber'


require_relative "../abilities"
require_relative "world_object"
require_relative "floating_text"

require_relative "../mixins/line_of_sight"
require_relative "../mixins/pathfinding"
require_relative "../mixins/has_contents"

module SmashAndGrab
module Objects
class Entity < WorldObject
  include Mixins::LineOfSight
  include Mixins::Pathfinding
  include Mixins::HasContents

  CLASS = :entity

  SPRITE_WIDTH, SPRITE_HEIGHT = 66, 66
  PORTRAIT_WIDTH, PORTRAIT_HEIGHT = 36, 36

  STATS_BACKGROUND_COLOR = Color.rgba 0, 0, 0, 180
  STATS_HP_COLOR = Color.rgb 0, 200, 0
  STATS_MP_COLOR = Color::rgb 50, 50, 255
  STATS_AP_COLOR = Color::YELLOW
  STATS_EP_COLOR = Color::RED
  PIP_WIDTH, PIP_SEP_WIDTH = 1.5, 0.5
  STATS_WIDTH = PIP_WIDTH * 5 + PIP_SEP_WIDTH * 4
  STATS_HALF_WIDTH = STATS_WIDTH / 2
  STATS_USED_SATURATION = 0.5

  ACTOR_NAME_COLOR = Color.rgb 50, 200, 50
  TARGET_NAME_COLOR = Color.rgb 50, 200, 50
  DAMAGE_NUMBER_COLOR = Color::RED

  COLOR_ACTIVE = Color::rgb 255, 255, 255
  COLOR_ACTIVE_NO_MOVE = STATS_AP_COLOR
  COLOR_ACTIVE_NO_ACTION = STATS_MP_COLOR
  COLOR_ACTIVE_FINISHED = Color.rgb 70, 70, 70
  COLOR_INACTIVE = Color::BLACK

  class << self
    def config; @config ||= YAML.load_file(File.expand_path("config/map/entities.yml", EXTRACT_PATH)); end
    def types; config.keys; end
    def sprites; @sprites ||= SpriteSheet["entities.png", SPRITE_WIDTH, SPRITE_HEIGHT, 8]; end
    def portraits; @portraits ||= SpriteSheet["entity_portraits.png", PORTRAIT_WIDTH, PORTRAIT_HEIGHT, 8]; end
  end

  event :ended_turn
  event :started_turn

  attr_reader :faction, :type, :portrait, :default_faction_type
  attr_reader :movement_points, :max_movement_points,
              :action_points, :max_action_points,
              :health_points, :max_health_points,
              :energy_points, :max_energy_points

  def minimap_color; @faction.minimap_color; end
  def active?; @faction.active?; end
  def inactive?; @faction.inactive?; end

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

  def energy_points=(energy_points)
    @energy_points = energy_points
    publish :changed
    @energy_points
  end

  alias_method :hp, :health_points
  alias_method :max_hp, :max_health_points

  alias_method :mp, :movement_points
  alias_method :mp=, :movement_points=
  alias_method :max_mp, :max_movement_points

  alias_method :ap, :action_points
  alias_method :ap=, :action_points=
  alias_method :max_ap, :max_action_points

  alias_method :ep, :energy_points
  alias_method :ep=, :energy_points=
  alias_method :max_ep, :max_energy_points

  def to_s; "<#{self.class.name}/#{@type}##{id} #{tile ? grid_position : "[off-map]"}>"; end
  def alive?; @health_points > 0 and @tile; end
  def title; t.title; end
  def colorized_name; faction.class::TEXT_COLOR.colorize name; end

  def bystander?; faction.is_a? Factions::Bystanders; end
  def goody?; faction.is_a? Factions::Goodies; end
  def baddy?; faction.is_a? Factions::Baddies; end

  def initialize(map, data)
    @type = data[:type]
    config = self.class.config[data[:type]]

    @default_faction_type = config[:faction]
    @faction = nil

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

    @max_health_points = config[:health_points]
    @health_points = data[:health_points] || @max_health_points

    @max_energy_points = if @max_action_points == 2
                           1
                         else
                           0
                         end
    @energy_points = data[:energy_points] || @max_energy_points

    # Load other abilities of the entity from config.
    @abilities = {}

    # Everyone who has movement_points has the ability to move, without it needing to be explicit.
    @abilities[:move] = Abilities.ability(self, type: :move) if max_movement_points > 0

    if config[:abilities]
      config[:abilities].each do |ability_data|
        @abilities[ability_data[:type]] = Abilities.ability(self, ability_data)
      end
    end

    if max_ap > 0
      @abilities[:pick_up] = Abilities.ability(self, type: :pick_up)
      @abilities[:drop] = Abilities.ability(self, type: :drop)
    end

    @tmp_contents_id = data[:contents_id] # Need to wait until all objects are loaded before picking it up.

    @queued_activities = []

    @stat_bars_record = nil
    subscribe :changed do
      @stat_bars_record = nil
    end
  end

  def faction=(faction)
    @faction.remove self if @faction
    @faction = faction
    @faction << self
  end

  def has_ability?(type); @abilities.has_key? type; end
  def ability(type); @abilities[type]; end

  def health_points=(value)
    original_health = @health_points
    @health_points = [value, 0].max

    # Show damage/healing as a floating number.
    if original_health != @health_points
      text, color = if @health_points > original_health
                      ["+#{@health_points - original_health}", Color::GREEN]
                    else
                      [(@health_points - original_health).to_s, Color::RED]
                    end

      FloatingText.new(text, color: color, x: x, y: y - height / 3, zorder: y - 0.01)
      publish :changed
    end

    if @health_points == 0 and @tile
      parent.publish :game_info, "#{colorized_name} was vanquished!"

      # Leave the tile, then drop anything we are carrying into it.
      # TODO: this is not undo/redoable!
      old_tile = tile
      self.tile = nil
      drop old_tile if contents

      @queued_activities.empty?
    end

    @health_points
  end
  alias_method :hp=, :health_points=

  # Called from GameActions::Ability
  # Also used to un-melee :)
  def make_melee_attack(target, damage)
    add_activity do
      if damage == 0 # Missed
        face target
        self.z += 10
        delay 0.1
        self.z -= 10

        parent.publish :game_info, "#{colorized_name} swung at #{target.colorized_name}, but missed"
        missed target

      elsif damage > 0 # do => wound
        face target
        self.z += 10
        delay 0.1
        self.z -= 10

        # Can be dead at this point if there were 2-3 attackers of opportunity!
        if target.alive?
          parent.publish :game_info, "#{colorized_name} smashed #{target.colorized_name} for {#{DAMAGE_NUMBER_COLOR.colorize damage}}"
          target.hp -= damage

          target.color = Color.rgb(255, 100, 100)
          delay 0.1
          target.color = Color::WHITE
        else
          parent.publish :game_info, "#{colorized_name} kicked #{target.colorized_name} while they were down"
        end
      else # undo => heal
        target.color = Color.rgb(255, 100, 100)
        delay 0.1
        target.hp -= damage
        target.color = Color::WHITE

        self.z += 10
        delay 0.1
        self.z -= 10
      end
    end
  end

  def missed(target)
    FloatingText.new("Miss!", color: Color::YELLOW, x: target.x, y: target.y - target.height / 3, zorder: target.y - 0.01)
  end

  def make_ranged_attack(target, damage)
    add_activity do
      if damage == 0
        face target

        parent.publish :game_info, "#{colorized_name} shot at #{target.colorized_name}, but missed"

        missed target
      elsif damage > 0 # do => wound
        face target

        # Can be dead at this point if there were 2-3 attackers of opportunity!
        if target.alive?
          parent.publish :game_info, "#{colorized_name} shot #{target.colorized_name} for {#{DAMAGE_NUMBER_COLOR.colorize damage}}"
          target.hp -= damage

          target.color = Color.rgb(255, 100, 100)
          delay 0.1
          target.color = Color::WHITE
        else
          parent.publish :game_info, "#{colorized_name} shot #{target.colorized_name} while they were down"
        end
      else # undo => heal
        target.color = Color.rgb(255, 100, 100)
        delay 0.1
        target.hp -= damage
        target.color = Color::WHITE
      end
    end
  end

  def start_game
    @health_points = max_hp # Has to be done directly or you could take damage or heal from it :D
    self.mp = max_mp
    self.ap = max_ap
    self.ep = max_ep # Only set to full at start of game.
  end

  def start_turn
    self.mp = max_mp
    self.ap = max_ap
    publish :started_turn
    publish :changed
  end

  def end_turn
    publish :ended_turn
    publish :changed
  end

  # Color of circular base you stand on.
  def base_color
    if active?
      if move?
        ap > 0 ? COLOR_ACTIVE : COLOR_ACTIVE_NO_ACTION
      else
        ap > 0 ? COLOR_ACTIVE_NO_MOVE : COLOR_ACTIVE_FINISHED
      end
    else
      COLOR_INACTIVE
    end
  end

  def draw
    return unless alive?

    if active?
      color = base_color.dup
      color.alpha = 60
      Image["tile_selection.png"].draw_rot x, y, y, 0, 0.5, 0.5, 1, 1, color
    end

    super()

    draw_stat_bars if parent.zoom >= 2
  end

  def draw_stat_pips(value, max, color, y)
    # Draw a background which appears between and underneath the pips.
    width = (max - 1) * PIP_SEP_WIDTH + max * PIP_WIDTH
    $window.pixel.draw -PIP_SEP_WIDTH, y - PIP_SEP_WIDTH, 0, width + PIP_SEP_WIDTH * 2, 1 + PIP_SEP_WIDTH * 2, STATS_BACKGROUND_COLOR

    # Draw the pips themselves.
    max.times do |i|
      if i < value and alive?
        pip_color = color
      else
        pip_color = color.dup
        pip_color.red *= STATS_USED_SATURATION
        pip_color.blue *= STATS_USED_SATURATION
        pip_color.green *= STATS_USED_SATURATION
      end
      $window.pixel.draw i * (PIP_WIDTH + PIP_SEP_WIDTH), y, 0, PIP_WIDTH, 1, pip_color
    end
  end

  def draw_stat_bars(options = {})
    options = {
        x: x - STATS_HALF_WIDTH,
        y: y - 4,
        zorder: y,
        factor_x: 1,
        factor_y: 1,
    }.merge! options

    @stat_bars_record ||= $window.record 1, 1 do
      # Health. 1 or two rows of up to 5 pips. Cannot have > 10 HP!
      full_rows, top_row_pips = max_hp.divmod 5
      case full_rows
        when 0
          draw_stat_pips(hp, top_row_pips, STATS_HP_COLOR, 1.5)
        when 1
          draw_stat_pips(hp - 5, top_row_pips, STATS_HP_COLOR, 0) if max_hp > 5
          draw_stat_pips([hp,  5].min, 5, STATS_HP_COLOR, 1.5)
        else # 2
          draw_stat_pips(hp - 5, 5, STATS_HP_COLOR, 0)
          draw_stat_pips([hp,  5].min, 5, STATS_HP_COLOR, 1.5)
      end

      # Action points. Cannot have > 5 AP!
      if max_ap > 0
        draw_stat_pips(ap, max_ap, STATS_AP_COLOR, 3)
      end

      # Energy counts down from the right.
      if max_ep > 0
        pips_width = PIP_WIDTH * 5 + PIP_SEP_WIDTH * 4
        $window.translate pips_width, 0 do
          $window.scale -1, 1 do
            draw_stat_pips ep, max_ep, STATS_EP_COLOR, 3
          end
        end
      end

      # Movement points. Just use a bar, since they aren't so critical and could be up to 20.
      if active?
        $window.pixel.draw -PIP_SEP_WIDTH, 4, 0, STATS_WIDTH + PIP_SEP_WIDTH * 2, 1 + PIP_SEP_WIDTH * 2, STATS_BACKGROUND_COLOR
        used_color = STATS_MP_COLOR.dup
        used_color.red *= STATS_USED_SATURATION
        used_color.blue *= STATS_USED_SATURATION
        used_color.green *= STATS_USED_SATURATION
        $window.pixel.draw 0, 4.5, 0, STATS_WIDTH, 1, used_color

        width = alive? ? STATS_WIDTH * mp : 0
        $window.pixel.draw 0, 4 + PIP_SEP_WIDTH, 0, width / [mp, max_mp].max, 1, STATS_MP_COLOR if active?
      end
    end

    @stat_bars_record.draw options[:x], options[:y], options[:zorder], options[:factor_x], options[:factor_y]
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

  # @param target [Tile, Objects::WorldObject, Numeric]
  def face(target)
    x_pos = target.is_a?(Numeric) ? target : target.x
    change_in_x = x_pos - x
    self.factor_x = change_in_x > 0 ? 1 : -1
  end

  # Actually perform movement (called from GameActions::Ability).
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

  def potential_ranged
    tiles = []

    if use_ability? :ranged
      ranged = ability :ranged
      min, max = ranged.min_range, ranged.max_range
      ((grid_x - max)..(grid_x + max)).each do |x|
        ((grid_y - max)..(grid_y + max)).each do |y|
          tile = map.tile_at_grid(x, y)
          if tile and tile != self.tile and
              not (tile.object.is_a?(Static)) and
              not (tile.object.is_a?(Entity) and friend?(tile.object)) and
              manhattan_distance(tile).between?(min, max) and line_of_sight? tile

            tiles << tile
          end
        end
      end
    end

    tiles
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
    if overwatch? target.tile
      parent.publish :game_info, "#{colorized_name} made a snap shot!"
      use_ability :ranged, target
    end
  end

  def overwatch?(tile)
    if alive? and use_ability? :ranged
      ranged = ability :ranged
      range = manhattan_distance tile

      range.between?(ranged.min_range, ranged.max_range) and line_of_sight? tile
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


  def use_ability(name, *args)
    raise "#{self} does not have ability: #{name.inspect}" unless has_ability? name
    map.actions.do :ability, ability(name).action_data(*args)
  end

  def use_ability?(name)
    alive? and has_ability?(name) and ap >= ability(name).action_cost and ability(name).use?
  end

  def to_json(*a)
    data = {
        :class => CLASS,
        type: type,
        id: id,
        health_points: health_points,
        movement_points: movement_points,
        action_points: action_points,
        energy_points: energy_points,
        contents_id: contents ? contents.id : nil,
        facing: factor_x > 0 ? :right : :left,
    }

    data[:tile] = grid_position if tile

    data.to_json(*a)
  end
end
end
end
