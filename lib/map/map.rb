require_relative 'faction'

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
      @recorded = $window.record do
        @tiles.each(&:draw)
      end
    end
  end

  # --------------------------------------------

  DATA_COMMENT = 'comment'
  DATA_GAME_STARTED_AT = 'game_started_at'
  DATA_LAST_SAVED_AT = 'last_saved_at'
  DATA_VERSION = 'version'
  DATA_SIZE = "map_size"
  DATA_TILES = "tiles"
  DATA_WALLS = "walls"
  DATA_OBJECTS = "objects"
  DATA_ACTIONS = 'actions'

  event :tile_contents_changed # An object moved or wall changed, etc.
  event :tile_type_changed # The actual type itself changed.
  event :wall_type_changed # The actual type itself changed.

  attr_reader :grid_width, :grid_height, :actions
  attr_reader :goodies, :baddies, :bystanders, :active_faction, :turn
    
  def to_rect; Rect.new(0, 0, @grid_width * Tile::WIDTH, @grid_height * Tile::HEIGHT); end

  # tile_classes: Nested arrays of Tile class names (Tile::Grass is represented as "Grass")
  def initialize(data)
    t = Time.now

    @world_objects = []
    @drawable_objects = []
    @drawable_walls = [] # Only the visible walls are stored. Others are ignored.

    @grid_width, @grid_height = data[DATA_TILES].size, data[DATA_TILES][0].size
    @tiles = data[DATA_TILES].map.with_index do |row, y|
      row.map.with_index do |type, x|
        Tile.new type, self, x, y
      end
    end

    # Fill the map with default walls (that is, no wall).
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        # Tile below.
        if y < @grid_height - 1
          Wall.new self, Wall::DATA_TYPE => 'none', Wall::DATA_TILES => [[x, y], [x, y + 1]]
        end

        # Tile to right.
        if x < @grid_width - 1
          Wall.new self, Wall::DATA_TYPE => 'none', Wall::DATA_TILES => [[x, y], [x + 1, y]]
        end
      end
    end

    data[DATA_WALLS].each do |wall_data|
      Wall.new self, wall_data
    end

    @goodies = Faction::Goodies.new self
    @baddies = Faction::Baddies.new self
    @bystanders = Faction::Bystanders.new self

    @factions = [@baddies, @goodies, @bystanders] # And order of play.

    data[DATA_OBJECTS].each do |object_data|
      case object_data[WorldObject::DATA_CLASS]
        when Entity::CLASS
          Entity.new self, object_data
        when StaticObject::CLASS
          StaticObject.new self, object_data
        else
          raise "Bad object class #{object_data[WorldObject::DATA_CLASS].inspect}"
      end
    end

    @actions = GameActionHistory.new self, data[DATA_ACTIONS]

    @turn, active_faction_index  = @actions.completed_turns.divmod @factions.size
    @active_faction = @factions[active_faction_index]

    @start_time = data[DATA_GAME_STARTED_AT] || Time.now

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
    @world_objects.index(object) || raise(ArgumentError, "Bad id #{id.inspect}")
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
    current_faction.end_turn

    start_turn # For the next faction.
  end

  def record
    @recorded_tiles = $window.record do
      @tiles.flatten.each(&:draw)
    end
  end

  def passable_tiles
    @tiles.flatten.select {|t| t.passable? nil }
  end
  
  def tile_at_position(x, y)
    x += Tile::WIDTH / 2
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
  
  # Draws all tiles (only) visible in the window.
  def draw_tiles(offset_x, offset_y, zoom)
    @recorded_tiles.draw -offset_x, -offset_y, ZOrder::TILES, zoom, zoom
  end

  # Add an object to the map.
  def <<(object)
    raise "can't add null object" if object.nil?

    case object
      when Entity, StaticObject
        @world_objects << object
      when Wall
        @drawable_walls << object
      else
        raise object.inspect
    end

    @drawable_objects << object
  end

  # Permanently remove an object from the map.
  def remove(object)
    @drawable_objects.delete object

    case object
      when Entity, StaticObject
        @world_objects.delete object
      when Wall
        @drawable_walls.delete object
      else
        raise object.inspect
    end
  end

  def draw_objects
    @drawable_objects.each(&:draw)
  end

  def save_data
    {
        DATA_COMMENT => "Smash and Grab save game",
        DATA_VERSION => SmashAndGrab::VERSION,
        DATA_GAME_STARTED_AT => @start_time,
        DATA_LAST_SAVED_AT => Time.now,
        DATA_SIZE => [@grid_width, @grid_height],
        DATA_TILES => @tiles,
        DATA_WALLS => @drawable_walls,
        DATA_OBJECTS => @world_objects,
        DATA_ACTIONS => @actions,
    }
  end
end