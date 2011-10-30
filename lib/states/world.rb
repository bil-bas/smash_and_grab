require 'zlib'
require 'json'

class World < GameState
  include Log

  attr_reader :map, :minimap, :mouse_selection

  MAX_ZOOM = 0.5
  MIN_ZOOM = 4.0
  INITIAL_ZOOM = 2.0
  QUICKSAVE_FILE = File.expand_path("quicksave.sgs", EXTRACT_PATH)

  BACKGROUND_COLOR = Color.rgba(30, 10, 10, 255)
  
  def setup
    init_fps

    @start_time = Time.now

    # Create a map.
    possible_tiles = [
        *(['Concrete'] * 20),
        *(['Grass'] * 4),
        *(['Lava'] * 1),
    ]

    tile_data = Array.new(50) { Array.new(50) { possible_tiles.sample } }

    # Create a little house.
    wall_data = [
        # Back wall.
        { "type" => "HighConcreteWall", "tiles" => [[1, 2], [1, 3]] },
        { "type" => "HighConcreteWallWindow", "tiles" => [[2, 2], [2, 3]] },
        { "type" => "HighConcreteWallWindow", "tiles" => [[3, 2], [3, 3]] },
        { "type" => "HighConcreteWall", "tiles" => [[4, 2], [4, 3]] },

        # Left wall
        { "type" => "HighConcreteWall", "tiles" => [[0, 3], [1, 3]] },
        # { "type" => "HighConcreteWall", "tiles" => [[0, 4], [1, 4]] },
        { "type" => "HighConcreteWall", "tiles" => [[0, 5], [1, 5]] },
        { "type" => "HighConcreteWall", "tiles" => [[0, 6], [1, 6]] },

        # Front wall.
        { "type" => "HighConcreteWall", "tiles" => [[1, 6], [1, 7]] },
        { "type" => "HighConcreteWallWindow", "tiles" => [[2, 6], [2, 7]] },
        { "type" => "HighConcreteWallWindow", "tiles" => [[3, 6], [3, 7]] },
        { "type" => "HighConcreteWall", "tiles" => [[4, 6], [4, 7]] },

        # Right wall
        { "type" => "HighConcreteWall", "tiles" => [[4, 3], [5, 3]] },
        { "type" => "HighConcreteWall", "tiles" => [[4, 4], [5, 4]] },
        { "type" => "HighConcreteWall", "tiles" => [[4, 5], [5, 5]] },
        { "type" => "HighConcreteWall", "tiles" => [[4, 6], [5, 6]] },
    ]



    @map = Map.new "tiles" => tile_data, "walls" => wall_data, "entities" => [], "objects" => [], 'actions' => []
    empty_tiles = @map.passable_tiles.shuffle

    # Make some characters.
    t = Time.now
    200.times do
      tile = empty_tiles.pop
      Entity::Character.new(map, "tile" => [tile.grid_x, tile.grid_y], "facing" => ['left', 'right'].sample)
    end

    log.debug { "Entities placed on map in #{"%.3f" % (Time.now - t)} s" }

    @minimap = Minimap.new @map

    @fps_text = ""

    @camera_offset_x, @camera_offset_y = [0, -@map.to_rect.center_y]
    @zoom = INITIAL_ZOOM

    @mouse_selection = MouseSelection.new @map

    @font = Font.new $window, default_font_name, 24

    # Zoom in and out.
    on_input :wheel_down do
      zoom_by 0.5 # Zoom out.
    end

    on_input :wheel_up do
      zoom_by 2.0 # Zoom in.
    end

    on_input :escape do
      @map.end_turn
      @mouse_selection.turn_reset
    end

    add_inputs(f5: :quicksave,
               f6: :quickload,
               z: ->{ undo_action if holding? :left_control },
               y: ->{ redo_action if holding? :left_control }
    )
  end

  def undo_action
    @map.actions.undo if @map.actions.can_undo?
  end

  def redo_action
    @map.actions.redo if @map.actions.can_redo?
  end

  def quicksave
    save_game QUICKSAVE_FILE
  end

  def quickload
    load_game QUICKSAVE_FILE
  end

  def save_game(file)
    t = Time.now

    data = @map.save_data

    # Pretty generation is twice as slow as regular to_json.
    json = JSON.pretty_generate(data)

    log.debug { "Generated save game data in #{"%.3f" % (Time.now - t)} s" }

    t = Time.now

    Zlib::GzipWriter.open(file) do |gz|
      gz.write json
    end

    File.open("#{file}.txt", "w") {|f| f.write json } # DEBUG ONLY!

    log.debug { "Saved game data in #{"%.3f" % (Time.now - t)} s" }

    log.info { "Saved game as #{file} [#{File.size(file)} bytes]" }
  end

  def load_game(file)
    t = Time.now

    json = Zlib::GzipReader.open(file) do |gz|
      gz.read
    end

    log.debug { "Loaded game data in #{"%.3f" % (Time.now - t)} s" }

    data = JSON.parse(json)

    @map = Map.new(data)

    @mouse_selection.select nil
    @mouse_selection.map = @map

    @minimap.map = @map
    @minimap.refresh

    log.info { "Loaded game from #{file} [#{File.size(file)} bytes]" }
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
      @map.draw_tiles @camera_offset_x, @camera_offset_y, @zoom
    end

    # Draw objects, etc.
    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        1.times do
          @map.draw_objects
          @mouse_selection.draw @camera_offset_x, @camera_offset_y, @zoom
        end
      end
    end

    @minimap.draw

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
