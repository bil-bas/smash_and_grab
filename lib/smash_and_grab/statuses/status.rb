module SmashAndGrab::Statuses
  class << self
    include SmashAndGrab::Log
    def create(type, owner, duration)
      const_get(Inflector.camelize type).new owner, duration
    end
  end

  class Status
    include SmashAndGrab::Log

    attr_reader :duration, :owner
    def type; @type ||= Inflector.underscore(Inflector.demodulize(self.class.name)).to_sym; end

    def initialize(owner, duration)
      @owner, @duration = owner, duration

      @started_turn_handler = @owner.subscribe :started_turn do
        @duration -= 1
        tick
        destroy if @duration <= 0
      end

      log.info { "#{owner.name} gained #{type.inspect} for #{duration} turn(s)" }
    end

    def add_duration(duration)
      log.info { "#{owner.name} gained #{type.inspect} for another #{duration} turn(s)" }
      @duration += duration
    end

    def tick; end

    def destroy
      log.info { "#{owner.name} recovered from #{type.inspect}" }
      @started_turn_handler.unsubscribe
      @owner.remove_status self
    end

    def to_json(*a)
      { type: type, duration: duration }.to_json(*a)
    end
  end

  # On fire! You'll die quite quickly :)
  class Burning < Status
    def tick
      @owner.health_points -= 2
    end
  end

  # Poisoned, so you slowly die and can't move as fast.
  class Poisoned < Status
    def tick
      @owner.health_points -= 1
      @owner.movement_points -= 2
    end
  end

  # Held so you can't move.
  class Held < Status
    def tick
      @owner.movement_points = 0
    end
  end

  # Confused so you can't use any abilities.
  class Confused < Status
    def tick
      @owner.action_points = 0
    end
  end
end