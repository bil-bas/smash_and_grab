require_folder "abilities", %w[area melee move ranged sprint]

module SmashAndGrab::Abilities
  # Create an ability based on class name.
  # @param owner [Entity]
  # @option data :type [String] underscored name of Ability to create.
  class << self
    def ability(owner, data); const_get(Inflector.camelize data[:type]).new(owner, data); end
  end
end


