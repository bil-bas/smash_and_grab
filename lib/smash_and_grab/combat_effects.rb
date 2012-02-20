module SmashAndGrab
  class CombatEffects
    class Effect
      attr_reader :type, :value

      def initialize(type, value)
        @type, @value = type, value
      end

      def affect(target)
        return if value == 0

        config = CombatDice.config[type]
        if config[:affects]
          # Directly affect stat(s) right now.
          stat_affected = config[:affects]
          current_value = target.send stat_affected

          # If the entity is out of actions or energy, then lose health instead.
          if current_value < value and stat_affected != :health_points
            target.send :"#{stat_affected}=", 0
            target.health_points -= value - current_value
          else
            target.send :"#{stat_affected}=", current_value - value
          end
        elsif config[:status]
          # Gain (or extend) a status.
          target.add_status config[:status], value
        elsif type == :knockback
          # TODO: Implement this!
        else
          raise type
        end
      end

      def to_s; "#{value}&#{type.to_s[0, 1]};"; end
      def ==(other); other.is_a?(Effect) and other.type == type and other.value == value; end
    end

    def initialize(effects = [])
      @effects = []
      effects.each do |type, value|
        add type, value
      end
    end

    def add(type, value)
      @effects << Effect.new(type, value)
    end

    def affect(target)
      @effects.each {|e| e.affect target }
    end

    def missed?; @effects.all? {|e| e.value == 0 }; end
    def value; @effects.inject(0) {|memo, effect| memo + effect.value }; end
    def to_s; @effects.map(&:to_s).join "+"; end
    def to_json(*a); @effects.map {|e| [e.type, e.value] }.to_json(*a); end
    def ==(other); other.is_a?(CombatEffects) and other.instance_variable_get(:@effects) == @effects; end
  end
end