require_relative "../../teststrap"
require_relative "helpers/ability_helper"

context Abilities::Move do
  helper :tile do |i|
    @tiles ||= Hash.new do |hash, key|
      hash[key] = Tile.new('grass', nil, 0, key)
    end
    @tiles[i]
  end

  helper(:entity) { @entity ||= Object.new }
  helper(:tiles) { [tile(0), tile(1), tile(2)] }
  helper(:tile_positions) { tiles.map {|t| t.grid_position } }

  setup { Abilities.ability entity, type: :move }

  acts_like_an_ability Abilities::Move, :move, no_skill: true, no_action_cost: true

  asserts(:owner).equals { entity }
  asserts(:can_be_undone?)
  asserts(:skill).equals 0
  asserts(:action_cost).equals 0
  asserts(:to_json) { JSON.parse(topic.to_json).symbolize }.equals(
      type: :move,
      skill: 0, # TODO: Irrelevant for move?
      action_cost: 0 # TODO: Irrelevant for move? Not sure; perhaps some entities can move OR attack?
  )

  asserts("action_data with tile") do
    stub(topic.owner).id.returns 12 # Don't know why I need to repeat this.
    path = Object.new
    mock(path).tiles.returns tiles
    mock(path).move_distance.returns 3
    mock(path).last.returns tiles.last
    mock(tiles.last).object.returns nil
    topic.action_data path
  end.same_elements(
      ability: :move,
      skill: 0, # TODO: Irrelevant for move?
      action_cost: 0, # TODO: Irrelevant for move? Not sure; perhaps some entities can move OR attack?

      owner_id: 12,
      movement_cost: 3,
      target_id: nil, # TODO: Irrelevant for move?
      target_position: [0, 2], # TODO: Irrelevant for move?
      path: [[0, 0], [0, 1], [0, 2]]
  )

  context "#target_valid?" do
    should "if target contains an object" do
      mock(tile(2)).empty?.returns false
      topic.target_valid?(tile(2))
    end.equals false

    should "if target is an empty tile without a path" do
      mock(tile(2)).empty?.returns true
      mock(entity).path_to(tile(2)).returns nil
      topic.target_valid?(tile(2))
    end.equals false

    should "if target is an empty tile with a path" do
      mock(tile(2)).empty?.returns true
      mock(entity).path_to(tile(2)).returns tiles
      topic.target_valid?(tile(2))
    end.equals true
  end

  context "#do" do
    should "move the entity forwards" do
      mock(entity).move tile_positions, 4
      topic.do action_cost: 0, path: tile_positions, movement_cost: 4
      true
    end
  end

  context "#undo" do
    should "move the entity backwards" do
      mock(entity).move tile_positions.reverse, -4
      topic.undo action_cost: 0, path: tile_positions, movement_cost: 4
      true
    end
  end
end