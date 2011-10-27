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

  MOVE = 4

  attr_reader :faction

  def initialize(grid_x, grid_y, options = {})
    unless defined? @@sprites
      @@sprites = Image.load_tiles($window, File.expand_path("media/images/characters.png", EXTRACT_PATH), 32, 32, true)
    end

    options = {
        image: @@sprites.sample,
        factor_x: [-1, 1].sample,
    }.merge! options
     
    super(grid_x, grid_y, options)

    # TODO: Obviously, this is dumb way to do factions.
    # Get a hash of the image, so we can compare it.
    @faction = @image.hash
  end

  def friend?(character)
    # TODO: Make this faction-based or something.
    @faction == character.faction
  end

  def enemy?(character); not friend?(character); end

  def impassable?(character); enemy? character; end
  def passable?(character); friend? character; end

  def potential_moves(options = {})
    # Todo: Improve this by using Dijkstra's Algorithm instead of this brute-force method.

    options = {
        starting_tile: tile,
        distance: MOVE,
        ignore: [],
    }.merge! options

    starting_tile = options[:starting_tile]
    distance = options[:distance]

    tiles = starting_tile.adjacent_passable(self) - options[:ignore]
    tiles.push starting_tile if distance < MOVE
    if distance > 1
      tiles.map! { |t| potential_moves(starting_tile: t, distance: distance - 1, ignore: tiles) }
      tiles.flatten!
    end

    tiles.uniq!

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

        return new_path.tiles if tile == destination_tile

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

  def move_to(tile)
    change_in_x = tile.x - @tile.x

    # Turn based on movement.
    unless change_in_x == 0
      self.factor_x = change_in_x > 0 ? 1 : -1
    end

    @tile.remove_object self
    tile.add_object self
    @tile = tile
  end
end