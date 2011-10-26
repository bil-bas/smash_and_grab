class World < GameState
  attr_reader :map

  MAX_ZOOM = 1
  MIN_ZOOM = 4
  INITIAL_ZOOM = 2

  BACKGROUND_COLOR = Color.rgba(30, 10, 10, 255)
  
  def setup
    @objects = [] # Objects that need #update

    init_fps

    @map = Map.new 50, 50

    # Make some characters.
    200.times do
      add_object Character.new(rand(@map.grid_width), rand(@map.grid_height))
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
    start_at = Time.now

    if holding? :left
      @camera_offset_x -= 10.0
    elsif holding? :right
      @camera_offset_x += 10.0
    end

    if holding? :up
      @camera_offset_y -= 10.0
    elsif holding? :down
      @camera_offset_y += 10.0
    end

    @mouse_selection.tile = @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom.to_f,
                                                  (@camera_offset_y + $window.mouse_y) / @zoom.to_f)
    @mouse_selection.update

    @used_time += (Time.now - start_at).to_f
    recalculate_fps

    @fps_text = "Zoom: #{zoom} FPS: #{@fps.round} [#{@potential_fps.round}]"

  rescue => ex
    puts ex
    puts ex.backtrace
    exit
  end
  
  def draw
    start_at = Time.now

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

    @used_time += (Time.now - start_at).to_f

  rescue => ex
    puts ex
    puts ex.backtrace
    exit
  end

  def init_fps
    @fps_next_calculated_at = Time.now.to_f + 1
    @fps = @potential_fps = 0
    @num_frames = 0
    @used_time = 0
  end

  def recalculate_fps
    @num_frames += 1

    if Time.now.to_f >= @fps_next_calculated_at
      elapsed_time = @fps_next_calculated_at - Time.now.to_f + 1
      @fps = @num_frames / elapsed_time
      @potential_fps = @num_frames / [@used_time, 0.0001].max

      @num_frames = 0
      @fps_next_calculated_at = Time.now.to_f + 1
      @used_time = 0
    end
  end
end
