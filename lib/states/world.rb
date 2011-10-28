class World < GameState
  attr_reader :map

  MAX_ZOOM = 0.5
  MIN_ZOOM = 4.0
  INITIAL_ZOOM = 2.0

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
      zoom_by 0.5 # Zoom out.
    end

    on_input :wheel_up do
      zoom_by 2.0 # Zoom in.
    end
  end

  def zoom_by(factor)
    if (factor < 1 and @zoom > MAX_ZOOM) or (factor > 1 and @zoom < MIN_ZOOM)
      # Zoom on the mouse position if it is in the window, else zoom on the center position.
      focus_x, focus_y = if $window.mouse_x.between?(0, $window.width) and $window.mouse_y.between?(0, $window.height)
        [$window.mouse_x, $window.mouse_y]
      else
        [$window.width / 2, $window.height / 2]
      end

      x = (@camera_offset_x + focus_x) / @zoom
      y = (@camera_offset_y + focus_y) / @zoom
      @zoom *= factor
      @camera_offset_x = ((@zoom * x) - focus_x).round
      @camera_offset_y = ((@zoom * y) - focus_y).round
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

    @mouse_selection.tile = @map.tile_at_position((@camera_offset_x + $window.mouse_x) / @zoom,
                                                  (@camera_offset_y + $window.mouse_y) / @zoom)
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
          @mouse_selection.draw @camera_offset_x, @camera_offset_y, @zoom
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
