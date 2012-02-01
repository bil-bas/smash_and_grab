module Abilities
  # @abstract
  class Ability
    attr_reader :skill, :owner

    def can_be_undone?; true; end
    def action_cost; @action_cost == :all ? owner.max_action_points : @action_cost; end
    def type; Inflector.underscore(Inflector.demodulize(self.class.name)).to_sym; end

    protected
    def initialize(owner, data)
      @owner = owner

      @skill = data[:skill] || raise(ArgumentError ,"No skill value for #{owner} #{self.class.name}")
      @action_cost = data[:action_cost] || raise(ArgumentError, "No action_cost for #{owner} #{self.class.name}")
    end

    public
    # Data saved with the character.
    def to_json(*a)
      {
          type: type,
          skill: skill,
          action_cost: @action_cost,
      }.to_json(*a)
    end

    public
    # Data saved in the action list for a particular use of the ability (unless passive).
    def action_data
      {
          ability: type,
          skill: skill,
          action_cost: @action_cost,
          owner_id: owner.id
      }
    end

    def do(data)
      owner.action_points -= data[:action_cost] if data[:action_cost] > 0
    end

    def undo(data)
      owner.action_points += data[:action_cost] if data[:action_cost] > 0
    end

    def to_s
      "<#{self.class.name} owner=#{owner} skill=#{skill} cost=#{@action_cost.inspect}>"
    end
  end

  # Ability that has an effect every turn.
  # @abstract
  class ContinuousAbility < Ability
    def initialize(owner, data)
      @active = data[:active]
      super(owner, data)
    end
  end

  # Ability that gives a permanent effect of some kind.
  # @abstract
  class PassiveAbility < ContinuousAbility
    def initialize(owner, data)
      super(owner, { active: true }.merge!(data))
    end
  end

  # An ability that has an effect, but the player can turn it on and off. e.g. Invisibility.
  # @abstract
  class ToggleAbility < ContinuousAbility
    def initialize(owner, data)
      super(owner, { active: false }.merge!(data))
    end
  end

  # Ability that can be activated, but only on oneself.
  # @abstract
  class SelfAbility < Ability
  end

  # Ability that targets a particular tile.
  # @abstract
  class TargetedAbility < Ability
    def requires_line_of_sight?; true; end
    def target_valid?(tile); true; end

    def action_data(target_tile)
      target = target_tile.object ? target_tile.object.id : nil
      super().merge!(
          target_id: target,
          target_position: target_tile.grid_position
      )
    end
  end

  # An ability that requires that the actor be adjacent to the target
  # and will move them if necessary. E.g. Melee.
  # @abstract
  class TouchAbility < TargetedAbility
  end
end


