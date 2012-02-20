require_relative "ability"

module SmashAndGrab::Abilities
  class Flurry < SelfAbility
    def use?; super and owner.action_points == 0; end

    def initialize(owner, data)
      super(owner, data.merge(cost: { energy_points: 1 }, skill: NON_SKILL))
    end

    def tip
      "#{super} - gain an action at the cost of one energy"
    end

    def do(data)
      super data
      owner.action_points += 1
    end

    def undo(data)
      super data
      owner.action_points -= 1
    end
  end
end