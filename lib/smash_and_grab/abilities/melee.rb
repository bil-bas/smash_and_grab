require_relative "ability"

# Melee skill is required to even move (it is plain "move" if you have no actions) :)
module SmashAndGrab::Abilities
  class Melee < TouchAbility
    include SmashAndGrab::CombatDice

    def can_be_undone?; false; end

    def target_valid?(tile); tile.object.is_a?(Objects::Entity) and tile.object.enemy?(owner); end

    def tip
      "#{super} attack in hand-to-hand combat"
    end

    def to_hash
      super.merge! damage_types: @damage_types
    end

    def initialize(owner, data)
      super(owner, data.merge(cost: { action_points: 1 }))
      @damage_types = data[:damage_types] || raise(ArgumentError, "no :damage_types specified")
    end

    def action_data(target)
      super(target.tile).merge(
          effects: roll_dice(skill, @damage_types, target)
      )
    end

    def do(data)
      super(data)

      owner.make_attack target(data), data[:effects]
    end

    def undo(data)
      target = target(data)
      target.tile = owner.map.tile_at_grid(data[:target_position]) unless target.tile
      #owner.make_attack(target(data), data[:effects].map {|type, amount| [type, -amount] })

      super(data)
    end
  end
end