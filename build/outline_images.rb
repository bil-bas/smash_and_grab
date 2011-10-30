ORIGINAL_IMAGE_PATH = File.expand_path("../../raw_media/images", __FILE__)
MODIFIED_IMAGE_PATH = File.expand_path("../../media/images", __FILE__)

IMAGES = [
    ["characters.png", [32, 32], 8],
]

desc "Process images (double in size and add an outline)"
task :process_images do
  require 'texplay'
  require_relative '../lib/texplay_ext/color'
  require_relative '../lib/texplay_ext/image'
  require_relative '../lib/texplay_ext/window'

  $window = Gosu::Window.new(100, 100, false)

  IMAGES.each do |image_name, (width, height), num_columns|
    sprites = Gosu::Image.load_tiles($window, File.expand_path(image_name, ORIGINAL_IMAGE_PATH), width, height, false)

    large_sprites = sprites.map {|s| s.enlarge 2 }
    large_outlined = large_sprites.map {|s| s.outline }
    large_outlined.map.with_index do |outline, i|
      outline.clear(dest_ignore: :alpha, color: Gosu::Color.rgb(50, 50, 50))
      outline.splice large_sprites[i], 1, 1, alpha_blend: true
    end

    new_image = Gosu::Image.create large_outlined.first.width * num_columns,
                                   large_outlined.first.height * large_outlined.size / num_columns

    large_outlined.each_with_index do |sprite, i|
      row, column = i.divmod num_columns
      new_image.splice sprite, column * sprite.width, row * sprite.height
    end

    new_image.save(File.expand_path(image_name, MODIFIED_IMAGE_PATH))
  end
end