require_relative "../../teststrap"
require_relative "helpers/ability_helper"

describe Abilities::Sprint do
  helper(:entity) { @entity ||= Object.new }

  subject { Abilities.ability entity, type: :sprint, skill: 3 }

  behaves_like Abilities::Ability

  should "fail if not given the required arguments" do
    ->{ Abilities.ability entity, type: :sprint }.should.raise(ArgumentError).message.should.match /No skill value for/
  end

  should "be initialized" do
    subject.owner.should.equal entity
    subject.can_be_undone?.should.be.true
    subject.skill.should.equal 3

    stub(entity).max_action_points.returns 2
    subject.action_cost.should.equal 2
  end

  should "serialize to json correctly" do
    JSON.parse(subject.to_json).symbolize.should.equal(
      type: :sprint,
      skill: 3,
      action_cost: :all,
    )
  end

  should "generate appropriate action_data" do
    mock(entity).id.returns 12
    mock(entity).max_movement_points.returns 11
    subject.action_data.should.equal(
      ability: :sprint,
      skill: 3,
      action_cost: :all,

      owner_id: 12,
      movement_bonus: 5
    )
  end

  describe "owner has max_mp == 100" do
    { 1 => 1, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }.each do |skill, expected_bonus|
      should "have #movement_bonus == #{expected_bonus} with #skill == #{skill}" do
        mock(entity).max_movement_points.returns 100
        mock(subject).skill.returns skill
        subject.movement_bonus.should.equal expected_bonus
      end
    end
  end

  describe "#do" do
    should "increase movement points and decrease action points" do
      stub(entity).action_points.returns 2
      mock(entity, :action_points=).with 0
      mock(entity).movement_points.returns 5
      mock(entity, :movement_points=).with 10
      subject.do action_cost: 2, movement_bonus: 5
    end
  end

  describe "#undo" do
    should "decrease movement points and increase action points" do
      stub(entity).action_points.returns 0
      mock(entity, :action_points=).with 2
      stub(entity).movement_points.returns 10
      mock(entity, :movement_points=).with 5
      subject.undo action_cost: 2, movement_bonus: 5
    end
  end
end