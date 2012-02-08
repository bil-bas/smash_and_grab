require 'zlib'
require 'json'
require 'fileutils'

module SmashAndGrab
module States
class World < Fidgit::GuiState
  include Log

  attr_reader :map, :minimap

  MAX_ZOOM = 0.5
  MIN_ZOOM = 4.0
  INITIAL_ZOOM = 2.0
  BACKGROUND_COLOR = Color.rgba(35, 20, 20, 255)
  GRID_COLOR = Color.rgba(150, 150, 150, 150)

  QUICKSAVE_FILE = File.expand_path("quicksave.sgs", SAVE_PATH)
  AUTOSAVE_FILE = File.expand_path("autosave.sgs", SAVE_PATH)

  def create_gui; raise NotImplementedError; end

  def create_minimap
    @minimap.map = @map

    @map.subscribe :tile_contents_changed do |map, tile|
      @minimap.update_tile tile
    end

    @map.subscribe :wall_type_changed do |map, wall|
      wall.tiles.each {|t| @minimap.update_tile t }
    end

    @map.subscribe :tile_type_changed do |map, tile|
      @minimap.update_tile tile
    end
  end

  def initialize
    super()

    init_fps

    @camera_offset_x, @camera_offset_y = 0, 0
    @zoom = INITIAL_ZOOM

    @font = Font.new $window, default_font_name, 24
    @fps_text = ""

    # Zoom in and out.
    on_input :wheel_down do
      zoom_by 0.5 # Zoom out.
    end

    on_input :wheel_up do
      zoom_by 2.0 # Zoom in.
    end

    add_inputs(f5: :quicksave,
               f6: :quickload,
               z: ->{ undo_action if holding? :left_control },
               y: ->{ redo_action if holding? :left_control },
               escape: :pop_game_state
    )
  end

  def setup
    log.info "Entered State: #{self.class.name}"
    super()
  end


  def save_game_as(file)
    t = Time.now

    data = @map.save_data

    # Pretty generation is twice as slow as regular to_json.
    json = JSON.pretty_generate(data)

    FileUtils.mkdir_p File.dirname(file)

    Zlib::GzipWriter.open(file) do |gz|
      gz.write json
    end

    log.info { "Saved game as #{file} [#{File.size(file)} bytes] in #{"%.3f" % (Time.now - t) }s" }

    File.open("#{file}.json", "w") {|f| f.write json } # DEBUG ONLY!
  end

  def load_game(file, factions, options = {})
    t = Time.now

    json = Zlib::GzipReader.open(file) do |gz|
      gz.read
    end

    data = JSON.parse(json).symbolize

    @map =  Map.new data, factions, options
    @map.record_grid GRID_COLOR

    @camera_offset_x, @camera_offset_y = [0, -@map.to_rect.center_y]

    assign_entities_to_factions

    create_gui
    create_minimap

    log.info { "Loaded game from #{file} [#{File.size(file)} bytes] in #{"%.3f" % (Time.now - t) }s" }
  end

  def assign_entities_to_factions; raise NotImplementedError; end

  def autosave
    save_game_as AUTOSAVE_FILE
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

    if holding_any? :left, :a
      @camera_offset_x -= 10.0
    elsif holding_any? :right, :d
      @camera_offset_x += 10.0
    end

    if holding_any? :up, :w
      @camera_offset_y -= 10.0
    elsif holding_any? :down, :s
      @camera_offset_y += 10.0
    end

    @map.update

    super()

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
    $window.pixel.draw 0, 0, -Float::INFINITY, $window.width, $window.height, BACKGROUND_COLOR

    # Draw objects, etc.
    $window.translate -@camera_offset_x, -@camera_offset_y do
      $window.scale @zoom do
        @map.draw
      end
    end

    @minimap.draw

    @font.draw @fps_text, 220, 0, ZOrder::GUI

    super()

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
end
end
