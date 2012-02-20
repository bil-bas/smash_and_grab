require_relative "../statuses/status"

module SmashAndGrab::Mixins
  module HasStatus
    def add_status(type, duration)
      @statuses ||= []

      existing_status = @statuses.find {|s| s.type == type }
      if existing_status
        existing_status.add_duration duration
      else
        @statuses << SmashAndGrab::Statuses.create(type, self, duration)
      end
    end

    def remove_status(type)
      @statuses ||= []

      @statuses.delete_if {|s| s.type == type }
    end

    def to_hash
      super.merge! statuses: @statuses
    end

    def initialize(map, data, options)
      super map, data, options
      statuses = data[:statuses] || []
      @statuses = statuses.map {|d| SmashAndGrab::Statuses.create d[:type], self, d[:duration] }
    end
  end
end