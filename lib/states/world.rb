class World < GameState
  attr_reader :map

  MAX_ZOOM = 1
  MIN_ZOOM = 4
  INITIAL_ZOOM = 2

  BACKGROUND_COLOR = Color.rgba(30, 10, 10, 255)
  
  def setup
    @objects = [] # Objects that need #update

    @map = Map.new 50, 50
=begin
    # Make some animated objects.
    #100.times do |i|
    #  Enemy.new(self, [i * 16, rand * window.size.height])
    #end
=end

    # Make some static objects.
    200.times do
      add_object Tree.new([rand(@map.grid_width), rand(@map.grid_height)])
    end

    @fps_text = ""

    @camera_offset_x, @camera_offset_y = [0, -@map.to_rect.center_y]
    @zoom = INITIAL_ZOOM

    @mouse_selection = MouseSelection.new

    @font = Font.new $window, default_font_name, 24

    # Zoom in and out.
    on_input :wheel_down do
      @zoom /= 2 if @zoom > MAX_ZOOM
    end

    on_input :wheel_up do
      @zoom *= 2 if @zoom < MIN_ZOOM
    end
  end
  
  def add_object(object)
    @objects << object
  end
  
  def zoom
    @zoom
  end
    
  def update
    if holding? :left
      @camera_offset_x -= 10.0 / zoom
    elsif holding? :right
      @camera_offset_x += 10.0 / zoom
    end

    if holding? :up
      @camera_offset_y -= 10.0 / zoom
    elsif holding? :down
      @camera_offset_y += 10.0 / zoom
    end

    p [[@camera_offset_x, @camera_offset_y],
    [($window.mouse_x / @zoom.to_f),

      ($window.mouse_y / @zoom.to_f)]]
    @mouse_selection.tile = @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom.to_f,
                                                  (@camera_offset_y + $window.mouse_y) / @zoom.to_f)

    @fps_text = "Zoom: #{zoom} FPS: #{fps.round}"

  rescue => ex
    puts ex
    puts ex.backtrace
    exit
  end
  
  def draw
    # Colour the background.
    $window.draw_quad 0, 0, BACKGROUND_COLOR,
                      $window.width, 0, BACKGROUND_COLOR,
                      $window.width, $window.height, BACKGROUND_COLOR,
                      0, $window.height, BACKGROUND_COLOR,
                      ZOrder::BACKGROUND

    # Draw the flat tiles.
    1.times do
      @map.draw @camera_offset_x, @camera_offset_y, @zoom
    end

    # Draw objects, etc.
    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        1.times do
          @objects.each(&:draw)
          @mouse_selection.draw
        end
      end
    end

    @font.draw @fps_text, 0, 0, Float::INFINITY

  rescue => ex
    puts ex
    puts ex.backtrace
    exit
  end
end
