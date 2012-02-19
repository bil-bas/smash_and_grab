require_relative "ability"

module SmashAndGrab::Abilities
  class Sprint < ToggleAbility
    def initialize(owner, data)
      super(owner, data.merge(cost: { action_points: 1 }))

      owner.subscribe :ended_turn do
        @active = false
      end
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

    protected
    def activate(data)
      super
      owner.movement_points += data[:movement_bonus]
    end

    protected
    def deactivate(data)
      super
      owner.movement_points -= data[:movement_bonus]
    end
  end
end