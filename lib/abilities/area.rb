require_relative "ability"

module Abilities
  class Area < TargetedAbility
    def can_undo?; false; end

    def target_valid?(tile); true; end

    def action_data(target_tile)
      effects = {}

      tile_positions_affected.each do |tile_position|
        effects[tile_position] = {
            damage: random_damage
        }
      end

      super(target_tile).merge!(
          tiles_affected: effects
      )
    end

    def random_damage
      (skill - 1).times.find_all { rand(2) == 1 }.size + 1
    end

    def do(data)
      super(data)
      # TODO: affect area.
    end

    def undo(data)
      # TODO: unaffect area.
      super(data)
    end
  end
end
