require_relative "../../teststrap"
require_relative "helpers/ability_helper"

describe Abilities::Melee do
  helper(:entity) {@entity ||= Object.new }
  helper(:enemy) { @enemy ||= Object.new }
  helper(:tile) { @tile ||= Tile.new(:grass, nil, 1, 1) }

  subject { Abilities.ability entity, type: :melee, action_cost: 1, skill: 5 }

  behaves_like Abilities::Ability

  should "fail if not given the required arguments" do
    ->{ Abilities.ability entity, type: :melee }.should.raise(ArgumentError).message.should.match /No skill value for/
  end

  should "be initialized" do
    subject.owner.should.equal entity
    subject.can_be_undone?.should.be.false
    subject.skill.should.equal 5
    subject.action_cost.should.equal 1
  end

  should "serialize to json correctly" do
    JSON.parse(subject.to_json).symbolize.should.equal(
        type: :melee,
        skill: 5,
        action_cost: 1
    )
  end

  should "generate appropriate action_data" do
    stub(entity).id.returns 12
    stub(enemy).id.returns 13
    stub(tile).object.returns enemy
    stub(subject).random_damage.returns 5
    subject.action_data(tile).should.equal(
        ability: :melee,
        skill: 5,
        action_cost: 1,

        owner_id: 12,
        target_id: 13,
        target_position: [1, 1],
        damage: 5
    )
  end

  describe "#random_damage" do
    should "never give a value greater than skill" do
      stub(subject).rand(is_a(Integer)) {|x| x - 1 }
      subject.random_damage == 5
    end

    should "never give a value less than 1" do
      stub(subject).rand(is_a(Integer)) { 0 }
      subject.random_damage == 1
    end
  end

  describe "#do" do
    should "remove action points and health" do
      stub(enemy).health.returns 20
      mock(enemy, :health=).with 15

      stub(entity).map.stub!.object_by_id(13).returns enemy
      stub(entity).action_points.returns 1
      mock(entity, :action_points=).with 0

      subject.do action_cost: 1, target_id: 13, damage: 5 #, target_position: [1, 1]
      true
    end
  end

  describe "#undo" do
    should "give action points and health (if target alive)" do
      stub(enemy).tile.returns tile
      stub(enemy).health.returns 15
      mock(enemy, :health=).with 20

      stub(entity).map.stub!.object_by_id(13).returns enemy
      stub(entity).action_points.returns 0
      mock(entity, :action_points=).with 1

      subject.undo action_cost: 1, target_id: 13, damage: 5, target_position: [1, 1]
    end

    should "give action points, health and return to map (if target dead)" do
      stub(enemy).tile.returns nil
      stub(enemy).health.returns 0
      mock(enemy, :tile=).with tile
      mock(enemy, :health=).with 5

      stub(entity).map do
        map = Object.new
        stub(map).object_by_id(13).returns enemy
        stub(map).tile_at_grid([1, 1]).returns tile
      end
      stub(entity).action_points.returns 0
      mock(entity, :action_points=).with 1

      subject.undo action_cost: 1, target_id: 13, damage: 5, target_position: [1, 1]
    end
  end
end