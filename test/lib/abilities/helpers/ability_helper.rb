def acts_like_an_ability(klass, type, options = {})
  context "acting like an Ability" do
    asserts_topic.kind_of klass
    asserts(:type).equals type
    asserts("can_be_undone?? is a kind of Boolean") { [true, false].include? topic.can_be_undone? }

    unless options[:no_skill]
      asserts("create without skill") { Abilities.ability entity, type: type, action_cost: 1 }.raises ArgumentError, /No skill value for/
    end

    unless options[:no_action_cost]
      asserts("create without action_cost") { Abilities.ability entity, type: type, skill: 2 }.raises ArgumentError, /No action_cost for/
    end
  end
end