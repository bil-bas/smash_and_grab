require 'set'

class Entity < StaticObject
  class Character < Entity; end

  class Path
    attr_reader :cost, :move_distance, :current, :first

    def tiles; @path.tiles + [current]; end

    def initialize(path, current, destination, extra_move_distance)
      @path, @current = path, current

      @move_distance = @path.move_distance + current.cost + extra_move_distance
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

  DATA_TYPE = 'type'
  DATA_IMAGE_INDEX = 'image_index'
  DATA_TILE = 'tile'
  DATA_MOVEMENT_POINTS = 'movement_points'
  DATA_FACING = 'facing'
  MOVEMENT_POINTS_PER_TURN = 5

  attr_reader :faction, :movement_points

  def to_s; "<#{self.class.name} [#{tile.grid_x}, #{tile.grid_y}]>"; end

  def initialize(map, data)
    @map = map

    unless defined? @@sprites
      @@sprites = SpriteSheet.new("characters.png", 64 + 2, 64 + 2)
    end

    @image_index = data[DATA_IMAGE_INDEX]

    options = {
        image: @@sprites.each.to_a[@image_index],
        factor_x: data[DATA_FACING] == 'right' ? 1 : -1,
    }

    super(@map.tile_at_grid(*data[DATA_TILE]), options)

    # TODO: Obviously, this is dumb way to do factions.
    # Get a hash of the image, so we can compare it.
    @faction = @image.hash

    @movement_points = data[DATA_MOVEMENT_POINTS] || MOVEMENT_POINTS_PER_TURN

    @map << self
  end

  def turn_reset
    @movement_points = MOVEMENT_POINTS_PER_TURN
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

    exits = starting_tile.exits(self).select {|wall| not tiles.include? wall.destination(starting_tile, self) }
    exits.each do |wall|
      tile = wall.destination(starting_tile, self)
      unless tiles.include? tile
        path = path_to(tile)
        if path and path.move_distance <= @movement_points and path.move_distance >= tile.cost
          tiles.push tile
          potential_moves(starting_tile: tile, tiles: tiles) if @movement_points > path.move_distance
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
      exits = path.current.exits(self).select {|wall| not closed_tiles.include? wall.destination(path.current, self) }
      exits.each do |wall|
        tile = wall.destination(path.current, self)
        new_path = Path.new(path, tile, destination_tile, wall.movement_cost(self))

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

    @tile.remove_object self
    destination.add_object self

    [@tile, destination].each {|t| parent.minimap.update_tile t }

    @tile = destination

    parent.mouse_selection.select self
  end

  def minimap_color
    # TODO: Friend blue, enemy red.
    :red
  end

  def to_json(*a)
    {
        DATA_TYPE => Inflector.demodulize(self.class.name),
        DATA_IMAGE_INDEX => @image_index,
        DATA_TILE => [tile.grid_x, tile.grid_y],
        DATA_MOVEMENT_POINTS => @movement_points,
        DATA_FACING => factor_x > 0 ? :right : :left,
    }.to_json(*a)
  end
end