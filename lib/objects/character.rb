require 'set'

class Character < StaticObject
  class Path
    attr_reader :cost, :move_distance, :current, :first

    def tiles; @path.tiles + [current]; end

    def initialize(path, current, destination)
      @path, @current = path, current

      @move_distance = @path.move_distance + current.cost
      @first = @path.first
      @cost = (@move_distance * 16) +
          (current.x - destination.x).abs + (current.y - destination.y).abs
    end
  end

  class PathStart < Path
    attr_reader :tiles

    def cost; 0; end
    def move_distance; 0; end

    def initialize(tile)
      @current = tile
      @tiles = [tile]
    end
  end

  MOVE = 5

  attr_reader :faction, :movement_points

  def to_s; "<#{self.class.name} [#{tile.grid_x}, #{tile.grid_y}]>"; end

  def initialize(tile, options = {})
    unless defined? @@sprites
      @@sprites = SpriteSheet.new("characters.png", 32, 32, 8)
    end

    options = {
        image: @@sprites.each.to_a.sample,
        factor_x: [-1, 1].sample,
    }.merge! options
     
    super(tile, options)

    # TODO: Obviously, this is dumb way to do factions.
    # Get a hash of the image, so we can compare it.
    @faction = @image.hash

    turn_reset
  end

  def turn_reset
    @movement_points = MOVE
  end

  def friend?(character)
    # TODO: Make this faction-based or something.
    @faction == character.faction
  end

  def enemy?(character); not friend?(character); end

  def move?; @movement_points > 0; end
  def end_turn_on?(person); false; end
  def impassable?(character); enemy? character; end
  def passable?(character); friend? character; end

  def potential_moves(options = {})
    options = {
        starting_tile: tile,
        tiles: [],
    }.merge! options

    starting_tile = options[:starting_tile]
    tiles = options[:tiles]

    adjacent = starting_tile.adjacent_passable(self) - tiles
    adjacent.each do |t|
      unless tiles.include? t
        path = path_to(t)
        if path and path.move_distance <= @movement_points and path.move_distance >= t.cost
          tiles.push t
          potential_moves(starting_tile: t, tiles: tiles) if @movement_points > path.move_distance
        end
      end
    end

    tiles
  end

  # A* path-finding.
  def path_to(destination_tile)
    return nil unless destination_tile.passable? self
    return nil if destination_tile == tile

    closed_tiles = []
    open_paths = [PathStart.new(tile)]

    while open_paths.any?
      # Check the (expected) shortest path and move it to closed, since we have considered it.
      path = open_paths.min_by(&:cost)

      open_paths.delete path
      closed_tiles.push path.current

      # Check adjacent tiles.
      (path.current.adjacent_passable(self) - closed_tiles).each do |tile|
        new_path = Path.new(path, tile, destination_tile)

        return new_path if tile == destination_tile

        if repeated_path = open_paths.find {|p| p.current == tile }
          if new_path.move_distance < repeated_path.move_distance
            open_paths.delete repeated_path
            open_paths.push new_path
          end
        else
          open_paths.push new_path
        end
      end
    end

    nil # Failed to connect at all.
  end

  def move_to(tile, movement_cost)
    raise "Not enough movement points" unless movement_cost <= @movement_points

    @movement_points -= movement_cost

    change_in_x = tile.x - @tile.x

    # Turn based on movement.
    unless change_in_x == 0
      self.factor_x = change_in_x > 0 ? 1 : -1
    end

    @tile.remove_object self
    tile.add_object self

    [@tile, tile].each {|t| parent.minimap.update_tile t }

    @tile = tile
  end

  def minimap_color
    # TODO: Friend blue, enemy red.
    :red
  end

  def to_json(*a)
    {
        json_class: self.class.name,
        location: [tile.grid_x, tile.grid_y],
        movement_points: @movement_points,
        facing: factor_x > 0 ? :right : :left,
    }.to_json(*a)
  end

  def self.json_create(data)
    tile = $window.current_game_state.map.tile_at_grid(*data['location'])
    new(tile, factor_x: data['facing'])
  end
end