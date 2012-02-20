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

    class << self
      def config; @config ||= YAML.load_file(File.expand_path("config/map/statuses.yml", EXTRACT_PATH)); end
    end

    def initialize(owner, duration)
      @owner, @duration = owner, duration

      @started_turn_handler = @owner.subscribe :started_turn do
        tick
      end

      setup

      log.info { "#{owner.name} gained #{type.inspect} for #{duration} turn(s)" }
    end

    def add_duration(duration)
      log.info { "#{owner.name} gained #{type.inspect} for another #{duration} turn(s)" }
      @duration += duration
    end

    def setup; end

    def reduce_points(points_group)
      Status.config[type][points_group].each do |stat, amount|
        @owner.send :"#{stat}=", @owner.send(stat) + amount
      end
    end


    def tick
      reduce_points :tick
      @duration -= 1
      destroy if @duration <= 0
    end

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
  end

  # Poisoned, so you slowly die and can't move as fast.
  class Poisoned < Status
  end

  # Held so you can't move.
  class Held < Status
  end

  class Irradiated < Status
    def tick
      # If the entity is out of energy, then lose other points instead.
      reduce_points :fail if owner.energy_points == 0

      super
    end
  end

  # Confused so you can't use any abilities.
  class Stunned < Status
    def setup
      # Special case is that if you are stunned when you still have actions left, then lose them
      # and use up a turn of effect.
      tick if owner.action_points > 0
    end
  end
end