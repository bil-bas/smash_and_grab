require_relative "../../teststrap"
require_relative "helpers/ability_helper"

context Abilities::Melee do
  helper(:entity) {@entity ||= Object.new }
  helper(:enemy) { @enemy ||= Object.new }
  helper(:tile) { @tile ||= Tile.new('grass', nil, 1, 1) }

  setup { Abilities.ability entity, type: :melee, action_cost: 1, skill: 5 }

  acts_like_an_ability Abilities::Melee, :melee, no_action_cost: true

  asserts(:owner).equals { entity }
  denies(:can_be_undone?)
  asserts(:skill).equals 5
  asserts(:action_cost).equals 1
  asserts(:to_json) { JSON.parse(topic.to_json).symbolize }.equals(
      type: :melee,
      skill: 5,
      action_cost: 1
  )

  asserts("action_data with tile") do
    stub(entity).id.returns 12
    stub(enemy).id.returns 13
    stub(tile).object.returns enemy
    stub(topic).random_damage.returns 5
    topic.action_data tile
  end.same_elements(
      ability: :melee,
      skill: 5,
      action_cost: 1,

      owner_id: 12,
      damage: 5,
      target_id: 13,
      target_position: [1, 1]
  )

  context "#random_damage" do
    should "never give a value greater than skill" do
      stub(topic).rand(is_a(Integer)) {|x| x - 1 }
      topic.random_damage == 5
    end

    should "never give a value less than 1" do
      stub(topic).rand(is_a(Integer)) { 0 }
      topic.random_damage == 1
    end
  end

  context "#do" do
    should "remove action points and health" do
      stub(enemy).health.returns 20
      mock(enemy, :health=).with 15

      stub(entity).map.stub!.object_by_id(13).returns enemy
      stub(entity).action_points.returns 1
      mock(entity, :action_points=).with 0

      topic.do action_cost: 1, target_id: 13, damage: 5 #, target_position: [1, 1]
      true
    end
  end

  context "#undo" do
    should "give action points and health (if target alive)" do
      stub(enemy).tile.returns tile
      stub(enemy).health.returns 15
      mock(enemy, :health=).with 20

      stub(entity).map.stub!.object_by_id(13).returns enemy
      stub(entity).action_points.returns 0
      mock(entity, :action_points=).with 1

      topic.undo action_cost: 1, target_id: 13, damage: 5, target_position: [1, 1]
      true
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

      topic.undo action_cost: 1, target_id: 13, damage: 5, target_position: [1, 1]
      true
    end
  end
end