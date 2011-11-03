require_relative 'action_history'
require_relative 'factions/faction'

class Map
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

  DATA_COMMENT = 'comment'
  DATA_GAME_STARTED_AT = 'game_started_at'
  DATA_LAST_SAVED_AT = 'last_saved_at'
  DATA_VERSION = 'version'
  DATA_SIZE = "map_size"
  DATA_TILES = "tiles"
  DATA_WALLS = "walls"
  DATA_ENTITIES = "entities"
  DATA_OBJECTS = "objects"
  DATA_ACTIONS = 'actions'

  attr_reader :grid_width, :grid_height, :actions, :entities
  attr_reader :goodies, :baddies, :bystanders, :active_faction, :turn
    
  def to_rect; Rect.new(0, 0, @grid_width * Tile::WIDTH, @grid_height * Tile::HEIGHT); end

  # tile_classes: Nested arrays of Tile class names (Tile::Grass is represented as "Grass")
  def initialize(data)
    t = Time.now

    @objects = []
    @entities = []
    @static_objects = []
    @walls = [] # Only the visible walls are stored. Others are ignored.

    @grid_width, @grid_height = data[DATA_TILES].size, data[DATA_TILES][0].size
    @tiles = data[DATA_TILES].map.with_index do |row, y|
      row.map.with_index do |tile_class, x|
        Tile.const_get(tile_class).new self, x, y
      end
    end

    # Fill the map with default walls (that is, no wall).
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        # Tile below.
        if y < @grid_height - 1
          Wall::None.new self, Wall::DATA_TILES => [[x, y], [x, y + 1]]
        end

        # Tile to right.
        if x < @grid_width - 1
          Wall::None.new self, Wall::DATA_TILES => [[x, y], [x + 1, y]]
        end
      end
    end

    data[DATA_WALLS].each do |wall_data|
      Wall.const_get(wall_data[Wall::DATA_TYPE]).new self, wall_data
    end

    @goodies = Faction::Goodies.new self
    @baddies = Faction::Baddies.new self
    @bystanders = Faction::Bystanders.new self

    @factions = [@baddies, @goodies, @bystanders] # And order of play.

    data[DATA_ENTITIES].each do |entity_data|
      Entity.const_get(entity_data[Entity::DATA_TYPE]).new self, entity_data
    end

    @actions = ActionHistory.new self, data[DATA_ACTIONS]

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

  def <<(object)
    case object
      when Entity
        @entities << object
      when Wall::None
        return # Do nothing. We don't need to draw them anyway.
      when Wall
        @walls << object
    end

    @objects << object
  end

  def remove(object)
    @objects.delete object

    case object
      when Entity
        @entities.delete object
      when Wall::None
        raise "Can't remove a Wall::None, since we don't care about them"
      when Wall
        @walls.delete object
    end
  end

  def draw_objects
    @objects.each(&:draw)
  end

  def save_data
    {
        DATA_COMMENT => "Smash and Grab save game",
        DATA_VERSION => SmashAndGrab::VERSION,
        DATA_GAME_STARTED_AT => @start_time,
        DATA_LAST_SAVED_AT => Time.now,
        DATA_SIZE => [@grid_width, @grid_height],
        DATA_TILES => @tiles,
        DATA_WALLS => @walls,
        DATA_ENTITIES => @entities,
        DATA_OBJECTS => @static_objects,
        DATA_ACTIONS => @actions,
    }
  end
end