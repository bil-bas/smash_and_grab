require_relative "ability"

module SmashAndGrab::Abilities
  class Ranged < TargetedAbility
    attr_reader :min_range, :max_range

    def can_be_undone?; false; end

    # TODO: Take into account min/max range and LOS.
    def target_valid?(tile); !!(tile.object.is_a?(Objects::Entity) and tile.object.enemy?(owner)); end

    def initialize(owner, data)
      data = {
          action_cost: 1,
          min_range: 2 # Can't fire at adjacent (melee) squares.
      }.merge data

      @min_range = data[:min_range]
      @max_range = data[:max_range] || raise(ArgumentError, "no :max_range specified")

      super(owner, data)
    end

    def tip
      "#{super} attack in ranged combat, at range #{min_range}..#{max_range}"
    end

    def to_hash
      super.merge(
          min_range: @min_range,
          max_range: @max_range,
      )
    end

    def action_data(target)
      super(target.tile).merge!(
          damage: random_damage
      )
    end

    def random_damage
      # 0..skill as damage in a bell-ish curve.
      skill.times.find_all { rand(6) + 1 <= 2 }.size # 2 potential hits on each d6.
    end

    def do(data)
      super(data)

      owner.make_ranged_attack(target(data), data[:damage])
    end

    def undo(data)
      target = target(data)
      target.tile = owner.map.tile_at_grid(data[:target_position]) unless target.tile
      owner.make_ranged_attack(target(data), -data[:damage])

      super(data)
    end
  end
end
