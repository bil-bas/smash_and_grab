require_relative "../../teststrap"
require_relative "helpers/ability_helper"

context Abilities::Sprint do
  helper(:entity) { @entity ||= Object.new }

  setup { Abilities.ability entity, type: :sprint, skill: 3, action_cost: :all }

  acts_like_an_ability Abilities::Sprint, :sprint, no_action_cost: true

  asserts(:owner).equals { entity }
  asserts(:can_be_undone?)
  asserts(:skill).equals 3

  asserts(:effective_action_cost) do
    mock(entity).max_action_points.returns 2
    topic.action_cost
  end.equals 2

  asserts(:action_cost) do
    mock(entity).max_action_points.returns 2
    topic.action_cost
  end.equals 2

  asserts(:to_json) { JSON.parse(topic.to_json).symbolize }.equals(
      type: :sprint,
      skill: 3,
      action_cost: :all,
  )

  asserts(:action_data) do
    mock(entity).id.returns 12
    mock(entity).max_movement_points.returns 11
    topic.action_data
  end.same_elements(
      ability: :sprint,
      skill: 3,
      action_cost: :all,

      owner_id: 12,
      movement_bonus: 5
  )

  context "owner has max_mp == 100" do
    { 1 => 1, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }.each do |skill, bonus|
        asserts "movement_bonus with skill #{skill}" do
          mock(entity).max_movement_points.returns 100
          mock(topic).skill.returns skill
          topic.movement_bonus
        end.equals bonus
    end
  end

  context "#do" do
    should "increase movement points and decrease action points" do
      stub(entity).action_points.returns 2
      mock(entity, :action_points=).with 0
      mock(entity).movement_points.returns 5
      mock(entity, :movement_points=).with 10
      topic.do action_cost: 2, movement_bonus: 5
      true
    end
  end

  context "#undo" do
    should "decrease movement points and increase action points" do
      stub(entity).action_points.returns 0
      mock(entity, :action_points=).with 2
      mock(entity).movement_points.returns 10
      mock(entity, :movement_points=).with 5
      topic.undo action_cost: 2, movement_bonus: 5
      true
    end
  end
end