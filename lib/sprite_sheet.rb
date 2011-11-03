class SpriteSheet
  extend Forwardable

  def_delegators :@sprites, :map, :each

  def initialize(file, width, height, tiles_wide = 0)
    @sprites = Image.load_tiles($window, File.expand_path(file, Image.autoload_dirs[0]), width, height, false)
    @tiles_wide = tiles_wide
  end

  def [](x, y = 0)
    @sprites[y * @tiles_wide + x]
  end
end