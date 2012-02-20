require_relative "ability"

module SmashAndGrab::Abilities
  class SecondWind < SelfAbility
    def use?; super and owner.hp <= (owner.max_hp - skill); end

    def initialize(owner, data)
      super(owner, data.merge(cost: { energy_points: 1 }))
    end

    def tip
      "#{super} - heal #{skill} health at the cost of one energy"
    end

    def do(data)
      super data
      owner.health_points += skill
    end

    def undo(data)
      super data
      owner.health_points -= skill
    end
  end
end