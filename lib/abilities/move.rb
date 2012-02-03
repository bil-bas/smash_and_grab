require_relative "ability"

module SmashAndGrab::Abilities
  class Move < TargetedAbility
    def can_undo?; true; end

    def target_valid?(tile); !!(tile.empty? and owner.path_to(tile)); end

    def initialize(owner, data)
      super(owner, data.merge(skill: 0, action_cost: 0))
    end

    def action_data(path)
      super(path.last).merge(
          path: path.tiles.map(&:grid_position),
          movement_cost: path.move_distance
      )
    end

    def do(data)
      super(data)

      owner.move data[:path], data[:movement_cost]
    end

    def undo(data)
      owner.move data[:path].reverse, -data[:movement_cost]

      super(data)
    end
  end
end