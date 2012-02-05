require_relative "ability"

module SmashAndGrab::Abilities
  class Sprint < SelfAbility
    def initialize(owner, data)
      super(owner, data.merge(action_cost: :all))
    end

    def movement_bonus
      base = owner.max_movement_points
      bonus = case skill
                when 1 then 1.0
                when 2 then base * 0.25
                when 3 then base * 0.50
                when 4 then base * 0.75
                when 5 then base * 1.00
                else
                  raise "Bad skill level #{skill}"
              end

      [bonus.floor, 1].max
    end

    def tip
      "#{super} gain #{movement_bonus} movement points at cost of all actions"
    end

    def action_data
      super().merge(
          movement_bonus: movement_bonus
      )
    end

    def do(data)
      super(data)

      owner.movement_points += data[:movement_bonus]
    end

    def undo(data)
      owner.movement_points -= data[:movement_bonus]

      super(data)
    end
  end
end