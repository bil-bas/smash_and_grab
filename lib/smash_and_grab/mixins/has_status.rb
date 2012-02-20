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
  end
end