require_relative "ability"

# Melee skill is required to even move (it is plain "move" if you have no actions) :)
module SmashAndGrab::Abilities
  class Melee < TouchAbility
    def can_be_undone?; false; end

    def target_valid?(tile); tile.object.is_a?(Objects::Entity) and tile.object.enemy?(owner); end

    def tip
      "#{super} attack in hand-to-hand combat"
    end

    def initialize(owner, data)
      super(owner, data.merge(action_cost: 1))
    end

    def action_data(target)
      super(target.tile).merge(
          damage: random_damage
      )
    end

    def random_damage
      # 0..skill as damage in a bell-ish curve.
      skill.times.find_all { rand(6) + 1 <= 3 }.size # 3 potential hits on each d6.
    end

    def do(data)
      super(data)

      owner.make_melee_attack(target(data), data[:damage])
    end

    def undo(data)
      target = target(data)
      target.tile = owner.map.tile_at_grid(data[:target_position]) unless target.tile
      owner.make_melee_attack(target(data), -data[:damage])

      super(data)
    end
  end
end