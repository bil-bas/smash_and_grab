module SmashAndGrab
  module CombatDice
    SPRITE_WIDTH, SPRITE_HEIGHT = 16, 16

    # Blunt, Cosmic, Electric, Fire, Hold, Impaling, Knock-back, Mental & Poison.
    NUM_DAMAGE_TYPES = 9

    class << self
      def sprites; @sprites ||= SpriteSheet["combat_dice.png", SPRITE_WIDTH, SPRITE_HEIGHT, NUM_DAMAGE_TYPES]; end
      def config; @config ||= YAML.load_file(File.expand_path("config/map/combat_dice.yml", EXTRACT_PATH)); end

      # Register the all dice types and sides for use in text.
      # e.g. &fire2; or &cosmic0;
      def create_text_entities
        return if defined? @created_entities
        @created_entities = true
        config.each do |type, config|
          # 0..2 coming up on the dice
          (0..2).each do |side|
            Gosu::register_entity "#{type.to_s[0, 1]}#{side}", sprites[config[:spritesheet_column], side]
          end

          # 1 on the dice (general type of damage).
          Gosu::register_entity "#{type.to_s[0, 1]}", sprites[config[:spritesheet_column], 1]
        end
      end
    end

    # Text to show for whatever skill level ability has.
    def skill_pips
      case @damage_types.size
        when 1
          "&#{@damage_types[0][0, 1]};" * skill
        when 2
          "&#{@damage_types[0][0, 1]};" * skill.fdiv(2).ceil +
              "&#{@damage_types[1][0, 1]};" * skill.fdiv(2).floor
        else
          raise "must use one or two combat types"
      end
    end

    # If you have :fire, :mental at level 3, then 2 fire and 1 mental dice will be rolled.
    # Return might then be [[:fire, 2], [:fire, 0], [:mental, 1]], which translates as 2 DoT and lose one action.
    #
    def roll_dice(level, types, target)
      effects = CombatEffects.new

      case types.size
        when 1
          effects.add types[0], roll_typed_dice(level, types[0], target)
        when 2
          effects.add types[0], roll_typed_dice(level.fdiv(2).ceil, types[0], target)
          effects.add types[1], roll_typed_dice(level.fdiv(2).floor, types[1], target)
        else
          raise "must use one or two combat types"
      end

      effects
    end

    protected
    def roll_typed_dice(level, type, target)
      max = level + target.vulnerability_to(type)

      effective = [max - target.resistance_to(type), 0].max

      # Work out what the results actually are.
      resisted = [[type, :resisted]] * (max - effective)
      rolls = effective.times.map { roll_die type }

      rolls.inject(0) {|memo, _| memo + roll_die(type) }
    end

    protected
    # @return [Integer] Result.
    def roll_die(type)
      rolls = CombatDice.config[type][:sides]
      rolls[rand(0..5)]
    end
  end
end