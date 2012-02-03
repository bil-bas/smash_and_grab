require_relative "ability"

module SmashAndGrab::Abilities
  class Ranged < TargetedAbility
    def can_undo?; false; end

    def target_valid?(tile); !!(tile.object.is_a?(Objects::Entity) and tile.object.enemy?(owner)); end

    def action_data(target_tile)
      super(target_tile).merge!(
          damage: random_damage
      )
    end

    def random_damage
      # 1..skill as damage in a bell-ish curve.
      (skill - 1).times.find_all { rand(2) == 1 }.size + 1
    end

    def do(data)
      super(data)

      owner.map.object_by_id(data[:target_id]).health -= data[:damage]
    end

    def undo(data)
      target = owner.map.object_by_id(data[:target_id])
      target.health += data[:damage]
      target.tile = owner.map.tile_at_grid(data[:target_position]) unless target.tile

      super(data)
    end
  end
end
