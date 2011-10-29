class ZOrderRecorder
  class Row
    attr_reader :zorder

    def initialize(zorder)
      @zorder = zorder
      @objects = []
      @recording = nil
    end

    def <<(object)
      @objects << object
    end

    def draw(offset_x, offset_y, zoom)
      @recording.draw -offset_x, -offset_y, @zorder, zoom, zoom
    end

    def record
      @recording = $window.record do
        @objects.each(&:draw)
      end
    end
  end

  def initialize
    @rows = []
  end

  def record(objects)
    @rows.clear
    current_y = -100000
    current_row = nil

    objects.sort_by(&:zorder).each do |object|
      if object.y > current_y
        if current_row
          current_row.record
          @rows << current_row
        end

        current_row = Row.new object.y
        current_y = object.y
      end

      current_row << object
    end

    # Record any left-over object(s) on the bottom z-order.
    current_row.record
    @rows << current_row
  end

  def draw(offset_x, offset_y, zoom)
    @rows.each {|row| row.draw offset_x, offset_y, zoom }
  end
end
