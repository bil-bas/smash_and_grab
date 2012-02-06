require_relative "../../teststrap"
require_relative "helpers/ability_helper"

describe SmashAndGrab::Abilities::Sprint do
  before do
    @entity = Object.new
    mock(@entity).subscribe :ended_turn
  end

  subject { SmashAndGrab::Abilities.ability @entity, type: :sprint, skill: 3 }

  behaves_like SmashAndGrab::Abilities::Ability

  should "fail if not given the required arguments" do
    ->{ SmashAndGrab::Abilities.ability @entity, type: :sprint }.should.raise(ArgumentError).message.should.match /No skill value for/
  end

  should "be initialized" do
    stub(@entity).max_action_points.returns 2
    stub(@entity).action_points.returns 2
    stub(@entity).max_movement_points.returns 5
    stub(@entity).movement_points.returns 5

    subject.owner.should.equal @entity
    subject.can_be_undone?.should.be.true
    subject.skill.should.equal 3
    subject.active?.should.equal false
    subject.activate?.should.equal true
    subject.deactivate?.should.equal false

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
    mock(@entity).id.returns 12
    mock(@entity).max_movement_points.returns 11
    mock(@entity).max_action_points.returns 2
    subject.action_data.should.equal(
      ability: :sprint,
      skill: 3,
      action_cost: 2,

      owner_id: 12,
      movement_bonus: 5
    )
  end

  describe "owner has max_mp == 100" do
    { 1 => 1, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }.each do |skill, expected_bonus|
      should "have #movement_bonus == #{expected_bonus} with #skill == #{skill}" do
        mock(@entity).max_movement_points.returns 100
        mock(subject).skill.returns skill
        subject.movement_bonus.should.equal expected_bonus
      end
    end
  end

  # Do and undo operate the same; they toggle on/off based on whether the ability is active?
  [:do, :undo].each do |meth|
    describe "##{meth}" do
      should "toggle on to increase movement points and decrease action points" do
        stub(@entity).max_action_points.returns 2
        stub(@entity).action_points.returns 2
        stub(@entity).max_movement_points.returns 5
        stub(@entity).movement_points.returns 5

        mock(@entity).action_points = 0
        mock(@entity).movement_points = 10
        subject.send meth, action_cost: 2, movement_bonus: 5

        subject.activate?.should.equal false
        subject.deactivate?.should.equal true
      end

      should "toggle off to decrease movement points and increase action points" do
        # Activate first.
        subject.instance_variable_set :@active, true

        # Now deactivate.
        stub(@entity).max_action_points.returns 2
        stub(@entity).action_points.returns 0
        stub(@entity).max_movement_points.returns 5
        stub(@entity).movement_points.returns 10

        mock(@entity).action_points = 2
        mock(@entity).movement_points = 5
        subject.send meth, action_cost: 2, movement_bonus: 5

        stub(@entity).action_points.returns 2
        stub(@entity).movement_points.returns 5

        subject.activate?.should.equal true
        subject.deactivate?.should.equal false
      end
    end
  end
end