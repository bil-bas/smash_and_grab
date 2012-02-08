require_relative "ability"

# Pick up an object from the ground
module SmashAndGrab::Abilities
  class Drop < TargetedAbility
    def can_be_undone?; true; end
    def use?; !owner.contents.nil? and owner.tile.adjacent_tiles(owner).any?(&:empty?); end

    def tip
      "#{super} #{owner.contents ? owner.contents.name : "something" }"
    end

    def initialize(owner, data)
      super(owner, data.merge(action_cost: 1, skill: NON_SKILL))
    end

    def action_data
      # TODO: find a way to get a specific position.
      target_tile = owner.tile.adjacent_tiles(owner).find_all(&:empty?).sample

      super(target_tile).merge(
          target_id: owner.contents.id
      )
    end

    def do(data)
      super(data)

      owner.drop owner.map.tile_at_grid(*data[:target_position])
    end

    def undo(data)
      owner.pick_up target(data)

      super(data)
    end
  end
end