class World < GameState
  attr_reader :map
  
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

    @camera_offset_x, @camera_offset_y = [0, @map.to_rect.center_y]
    @zoom = 2

    @font = Font.new $window, default_font_name, 24

    on_input :wheel_down do
      @zoom /= 2 if @zoom > 1
    end

    on_input :wheel_up do
      @zoom *= 2 if @zoom < 4
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
      @camera_offset_x += 10.0 / zoom
    elsif holding? :right
      @camera_offset_x -= 10.0 / zoom
    end

    if holding? :up
      @camera_offset_y += 10.0 / zoom
    elsif holding? :down
      @camera_offset_y -= 10.0 / zoom
    end
          
    @fps_text = "Zoom: #{zoom} FPS: #{fps.round}"

  rescue => ex
    puts ex
    puts ex.backtrace
    exit
  end
  
  def draw
    1.times do
      @map.draw @camera_offset_x, @camera_offset_y, @zoom
    end

    $window.translate @camera_offset_x, @camera_offset_y do
      $window.scale @zoom do
        1.times do
          @objects.each(&:draw)
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
