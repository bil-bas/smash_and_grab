PORTRAIT_IMAGES = [
  # in, out, in-size, columns, out-rect.
  ["entities.png", "entity_portraits.png", [66, 66], 8, [14, 10, 36, 36]],
]

desc "Process images (cut out a portrait of each character)"
task create_portraits: :outline_images do
  require 'texplay'
  require_relative '../lib/smash_and_grab/texplay_ext/color'
  require_relative '../lib/smash_and_grab/texplay_ext/image'
  require_relative '../lib/smash_and_grab/texplay_ext/window'

  puts "=== Creating portraits ===\n\n"

  $window = Gosu::Window.new(100, 100, false)

  PORTRAIT_IMAGES.each do |image_in_name, image_out_name, (width, height), num_columns, (rect_x, rect_y, rect_width, rect_height)|
    puts "Making portraits from #{image_in_name}"

    sprites = Gosu::Image.load_tiles($window, File.expand_path(image_in_name, MODIFIED_IMAGE_PATH), width, height, false)
    sprites.each(&:refresh_cache)

    new_image = Gosu::Image.create rect_width * num_columns,
                                   rect_height * (sprites.size / num_columns)
    new_image.refresh_cache

    print "\n  Splicing:   "
    sprites.each.with_index do |sprite, i|
      row, column = i.divmod num_columns
      new_image.splice sprite, column * rect_width, row * rect_height,
                       crop: [rect_x, rect_y, rect_x + rect_width, rect_y + rect_height]
      print '.'
    end

    puts "\n\n"

    new_image.save(File.expand_path(image_out_name, MODIFIED_IMAGE_PATH))
  end
end