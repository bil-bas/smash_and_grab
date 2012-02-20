module SmashAndGrab
  class CombatEffects
    class Effect
      attr_reader :type, :value

      def initialize(type, value)
        @type, @value = type, value
      end

      def affect(target, origin_tile)
        return if value == 0

        config = Mixins::RollsDice.config[type]
        if config[:affects]
          # Directly affect stat(s) right now.
          stat_affected = config[:affects]
          current_value = target.send stat_affected

          target.send :"#{stat_affected}=", current_value - value
        elsif config[:status]
          # Gain (or extend) a status.
          target.add_status config[:status], value
        elsif type == :knockback
          target.knock_back value, origin_tile
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

    def affect(target, origin_tile)
      @effects.each {|e| e.affect target, origin_tile }
    end

    def missed?; @effects.all? {|e| e.value == 0 }; end
    def value; @effects.inject(0) {|memo, effect| memo + effect.value }; end
    def to_s; @effects.map(&:to_s).join "+"; end
    def to_json(*a); @effects.map {|e| [e.type, e.value] }.to_json(*a); end
    def ==(other); other.is_a?(CombatEffects) and other.instance_variable_get(:@effects) == @effects; end
  end
end