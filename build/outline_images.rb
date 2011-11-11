ORIGINAL_IMAGE_PATH = File.expand_path("../../raw_media/images", __FILE__)
MODIFIED_IMAGE_PATH = File.expand_path("../../media/images", __FILE__)

IMAGES = [
    ["entities.png", [32, 32], 8],
    ["objects.png",    [32, 32], 8],
    ["vehicles.png",   [128, 128], 3],
]

desc "Process images (double in size and add an outline)"
task :outline_images do
  require 'texplay'
  require_relative '../lib/texplay_ext/color'
  require_relative '../lib/texplay_ext/image'
  require_relative '../lib/texplay_ext/window'

  puts "=== Processing images ===\n\n"

  $window = Gosu::Window.new(100, 100, false)

  IMAGES.each do |image_name, (width, height), num_columns|
    puts "Processing #{image_name}"

    sprites = Gosu::Image.load_tiles($window, File.expand_path(image_name, ORIGINAL_IMAGE_PATH), width, height, false)
    sprites.each(&:refresh_cache)

    print "  Enlarging: "
    large_sprites = sprites.map do |sprite|
      print '.'
      sprite.enlarge 2
    end

    print "\n  Outlining: "
    large_outlined = large_sprites.map do |sprite|
      print '.'
      sprite.outline
    end

    new_image = Gosu::Image.create large_outlined.first.width * num_columns,
                                   large_outlined.first.height * large_outlined.size / num_columns
    new_image.refresh_cache

    print "\n  Splicing:   "
    large_outlined.each.with_index do |sprite, i|
      sprite.clear(dest_ignore: :alpha, color: Gosu::Color.rgb(50, 50, 50))
      sprite.splice large_sprites[i], 1, 1, alpha_blend: true
      row, column = i.divmod num_columns
      new_image.splice sprite, column * sprite.width, row * sprite.height
      print '.'
    end

    puts "\n\n"

    new_image.save(File.expand_path(image_name, MODIFIED_IMAGE_PATH))
  end
end