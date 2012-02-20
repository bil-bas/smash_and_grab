require_relative "ability"
require_relative "../mixins/rolls_dice"

module SmashAndGrab::Abilities
  class Ranged < TargetedAbility
    include SmashAndGrab::Mixins::RollsDice

    attr_reader :min_range, :max_range

    def can_be_undone?; false; end

    # TODO: Take into account min/max range and LOS.
    def target_valid?(tile); !!(tile.object.is_a?(Objects::Entity) and tile.object.enemy?(owner)); end

    def initialize(owner, data)
      data = {
          cost: { action_points: 1 },
          min_range: 2 # Can't fire at adjacent (melee) squares.
      }.merge data

      @min_range = data[:min_range]
      @max_range = data[:max_range] || raise(ArgumentError, "no :max_range specified")
      @damage_types = data[:damage_types] || raise(ArgumentError, "no :damage_types specified")

      super(owner, data)
    end

    def tip
      "#{super} attack in ranged combat, at range #{min_range}-#{max_range}"
    end

    def to_hash
      super.merge(
          min_range: @min_range,
          max_range: @max_range,
          damage_types: @damage_types
      )
    end

    def action_data(target)
      super(target.tile).merge!(
          effects: roll_dice(skill, @damage_types, target)
      )
    end


    def do(data)
      super(data)

      owner.make_attack(target(data), data[:effects])
    end

    def undo(data)
      target = target(data)
      target.tile = owner.map.tile_at_grid(data[:target_position]) unless target.tile
      #owner.make_ranged_attack(target(data), -data[:damage])

      super(data)
    end
  end
end
