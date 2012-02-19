module SmashAndGrab::Abilities
  # @abstract
  class Ability
    attr_reader :skill, :owner
    NON_SKILL = 0
    SKILL_LEVEL_DESCRIPTIONS = %w[Fair Good Excellent Heroic Legendary]

    def use?; true; end
    def can_be_undone?; true; end
    def action_cost; @cost[:action_points] || 0; end
    def type; Inflector.underscore(Inflector.demodulize(self.class.name)).to_sym; end

    def tip
      if skill > NON_SKILL
       "#{SKILL_LEVEL_DESCRIPTIONS[skill - 1]} #{type.capitalize} #{skill_pips}"
      else
        type.capitalize
      end
    end

    # Used in tip to show what dice will be rolled (or just indication of skill for a skill not based on dice).
    def skill_pips
      # TODO: use a nicer symbol for this.
      "*" * skill
    end

    protected
    def initialize(owner, data)
      @owner = owner

      @skill = data[:skill] || raise(ArgumentError ,"No skill value for #{owner} #{self.class.name}")
      @cost = data[:cost] || {} # Defaults to being a free skill.
    end

    public
    # Data saved with the character.
    def to_json(*a)
      to_hash.to_json(*a)
    end

    def to_hash
      {
          type: type,
          skill: skill,
          cost: @cost,
      }
    end

    public
    # Data saved in the action list for a particular use of the ability (unless passive).
    def action_data
      {
          ability: type,
          skill: skill,
          cost: @cost,
          owner_id: owner.id
      }
    end

    def do(data)
      owner_spend data[:cost]
    end

    def undo(data)
      owner_refund data[:cost]
    end

    def to_s
      "<#{self.class.name} owner=#{owner} skill=#{skill} cost=#{@cost.inspect}>"
    end

    protected
    def owner_spend(cost)
      return unless cost
      cost.each do |point_type, amount|
        owner.send(:"#{point_type}=", owner.send(point_type) - amount)
      end
    end

    protected
    def owner_refund(cost)
      return unless cost
      cost.each do |point_type, amount|
        owner.send(:"#{point_type}=", owner.send(point_type) + amount)
      end
    end
  end

  # Ability that has an effect every turn.
  # @abstract
  class ContinuousAbility < Ability
    def active?; @active; end

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
    def activate?; owner.action_points >= action_cost and not active?; end
    def deactivate?; owner.movement_points >= movement_bonus and active?; end

    def initialize(owner, data)
      super(owner, { active: false }.merge!(data))
    end

    def do(data)
      if active?
        deactivate data
      else
        activate data
      end
    end

    def undo(data)
      self.do data # Effect is based on current state, not on whether it is done or undone.
    end

    protected
    def activate(data)
      owner_spend data[:cost]
      @active = true
    end

    protected
    def deactivate(data)
      owner_refund data[:cost]
      @active = false
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

    protected
    def target(data); owner.map.object_by_id(data[:target_id]); end
  end

  # An ability that requires that the actor be adjacent to the target
  # and will move them if necessary. E.g. Melee or PickUp.
  # @abstract
  class TouchAbility < TargetedAbility
  end
end


