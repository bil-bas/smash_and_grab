require_relative 'faction'
require 'set'

module SmashAndGrab
class Map
  include Fidgit::Event
  include Log

  class TileRow
    attr_reader :zorder

    def initialize(zorder)
      @zorder = zorder
      @tiles = []
    end

    def <<(tile)
      @tiles << tile
    end

    def draw(offset_x, offset_y, zoom)
      @recorded.draw -offset_x, -offset_y, @zorder, zoom, zoom
    end

    def record
      @recorded = $window.record(1, 1) do
        @tiles.each(&:draw)
      end
    end
  end

  # --------------------------------------------

  event :tile_contents_changed # An object moved or wall changed, etc.
  event :tile_type_changed # The actual type itself changed.
  event :wall_type_changed # The actual type itself changed.

  attr_reader :grid_width, :grid_height, :actions
  attr_reader :goodies, :baddies, :bystanders, :active_faction, :turn, :factions
    
  def to_rect; Rect.new(0, 0, @grid_width * Tile::WIDTH, @grid_height * Tile::HEIGHT); end

  def add_effect(effect); @effects << effect; end
  def remove_effect(effect); @effects.delete effect; end

  # tile_classes: Nested arrays of Tile class names (Tile::Grass is represented as "Grass")
  def initialize(data)
    t = Time.now

    @effects = []
    @world_objects = []
    @drawable_objects = []
    @drawable_walls = [] # Only the visible walls are stored. Others are ignored.

    @grid_width, @grid_height = data[:tiles].size, data[:tiles][0].size
    @tiles = data[:tiles].map.with_index do |row, y|
      row.map.with_index do |type, x|
        Tile.new type, self, x, y
      end
    end

    # Fill the map with default walls (that is, no wall).
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        # Tile below.
        if y < @grid_height - 1
          Wall.new self, type: :none, tiles: [[x, y], [x, y + 1]]
        end

        # Tile to right.
        if x < @grid_width - 1
          Wall.new self, type: :none, tiles: [[x, y], [x + 1, y]]
        end
      end
    end

    data[:walls].each do |wall_data|
      Wall.new self, wall_data
    end

    @goodies = Factions::Goodies.new self
    @baddies = Factions::Baddies.new self
    @bystanders = Factions::Bystanders.new self

    @factions = [@baddies, @goodies, @bystanders] # And order of play.

    data[:objects].each do |object_data|
      case object_data[:class]
        when Objects::Entity::CLASS
          Objects::Entity.new self, object_data
        when Objects::Static::CLASS
          Objects::Static.new self, object_data
        when Objects::Vehicle::CLASS
          Objects::Vehicle.new self, object_data
        else
          raise "Bad object class #{object_data[:class].inspect}"
      end
    end

    @actions = GameActionHistory.new self, data[:actions]

    @turn, active_faction_index  = @actions.completed_turns.divmod @factions.size
    @active_faction = @factions[active_faction_index]

    @start_time = data[:game_started_at] || Time.now

    log.debug { "Map created in #{"%.3f" % (Time.now - t)} s" }

    record

    if @actions.empty?
      start_game
    else
      resume_game
    end

    # Ensure that if any tiles are changed, that the map is redrawn.
    subscribe :tile_type_changed do
      record
    end

    subscribe :wall_type_changed do |sender, wall|
      publish :tile_contents_changed, wall.tiles.first
    end
  end

  def object_by_id(id)
    raise "Bad id #{id.inspect}" unless (0...@world_objects.size).include? id
    @world_objects[id]
  end

  def id_for_object(object)
    @world_objects.index(object) || raise(ArgumentError, "Bad object #{object.inspect}")
  end

  def start_game
    @active_faction.start_game
  end

  def resume_game
    @active_faction.resume_game
  end

  def start_turn
    @active_faction.start_turn
  end

  def end_turn
    current_faction = @active_faction
    if @active_faction == @factions.last
      @turn += 1
      @active_faction = @factions.first
    else
      @active_faction = @factions[@factions.index(@active_faction) + 1]
    end

    @actions.do :end_turn

    start_turn # For the next faction.
  end

  def record
    @recorded_tiles = $window.record(1, 1) do
      @tiles.flatten.each(&:draw)
    end
  end

  def passable_tiles
    @tiles.flatten.select {|t| t.passable? nil }
  end
  
  def tile_at_position(x, y)
    x += Tile::WIDTH / 2.0
    y = y.to_f
    tile_at_grid(x / Tile::WIDTH - y / Tile::HEIGHT,
                 x / Tile::WIDTH + y / Tile::HEIGHT)
  end
  
  def tile_at_grid(x, y)
    if x >= 0 and x < @grid_width and y >= 0 and y < @grid_height
      @tiles[y][x]
    else
      nil
    end
  end

  # Add an object to the map.
  def add(object)
    raise "can't add null object" if object.nil?

    case object
      when Objects::Entity, Objects::Static, Objects::Vehicle
        @world_objects << object
      when Wall
        @drawable_walls << object
      else
        raise object.inspect
    end

    @drawable_objects << object
  end
  alias_method :<<, :add

  # Permanently remove an object from the map.
  def remove(object)
    @drawable_objects.delete object

    case object
      when Objects::Entity, Objects::Static, Objects::Vehicle
        @world_objects.delete object
      when Wall
        @drawable_walls.delete object
      else
        raise object.inspect
    end
  end

  def draw
    @recorded_tiles.draw 0, 0, ZOrder::TILES
    @drawable_objects.each(&:draw)
    @effects.each(&:draw)
  end

  def update
    @drawable_objects.each(&:update)
    @effects.each(&:update)
  end

  def record_grid(color)
    @grid_record = $window.record(1, 1) do
      # Lines top to bottom.
      @tiles.each do |row|
        tile = row.first
        $window.pixel.draw_rot tile.x - 16, tile.y, ZOrder::TILE_SELECTION, -26.55, 0, 0.5, row.size * 17.9, 1, color
      end

      # Lines left to right.
      @tiles.first.each do |tile|
        $window.pixel.draw_rot tile.x - 16, tile.y, ZOrder::TILE_SELECTION, +26.55, 0, 0.5, @grid_width * 17.9, 1, color
      end
    end
  end

  def draw_grid
    @grid_record.draw 0, 0, ZOrder::TILE_SELECTION
  end

  def save_data
    {
        comment: "Smash and Grab save game",
        version: SmashAndGrab::VERSION,
        game_started_at: @start_time,
        last_saved_at: Time.now,
        map_size: [@grid_width, @grid_height],
        tiles: @tiles,
        walls: @drawable_walls,
        objects: @world_objects,
        actions: @actions,
    }
  end
end
end