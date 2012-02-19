require_relative "ability"

# Pick up an object from the ground
module SmashAndGrab::Abilities
  class PickUp < TouchAbility
    def can_be_undone?; true; end

    def tip
      raise "n/a"
    end

    def initialize(owner, data)
      super(owner, data.merge(cost: { action_points: 1 }, skill: NON_SKILL))
    end

    def action_data(object)
      super(object.tile).merge({
      })
    end

    def do(data)
      super(data)

      owner.pick_up target(data)
    end

    def undo(data)
      owner.drop owner.map.tile_at_grid(*data[:target_position])

      super(data)
    end
  end
end