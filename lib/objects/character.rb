class Character < StaticObject
  MOVE = 4

  def initialize(grid_x, grid_y, options = {})
    unless defined? @@sprites
      @@sprites = Image.load_tiles($window, File.expand_path("media/images/characters.png", EXTRACT_PATH), 32, 32, true)
    end

    options = {
        image: @@sprites.sample,
        factor_x: [-1, 1].sample,
    }.merge! options
     
    super(grid_x, grid_y, options)
  end

  def potential_moves(options = {})
    options = {
        starting_tile: tile,
        distance: MOVE,
    }.merge! options

    starting_tile = options[:starting_tile]
    distance = options[:distance]

    tiles = starting_tile.adjacent_passable(self)
    tiles.push starting_tile if distance < MOVE
    if distance > 1
      tiles.map! { |t| potential_moves(starting_tile: t, distance: distance - 1) }
      tiles.flatten!
    end

    tiles.uniq!

    tiles
  end
end