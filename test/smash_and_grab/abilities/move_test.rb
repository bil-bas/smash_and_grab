require_relative "../../teststrap"
require_relative "helpers/ability_helper"

describe SmashAndGrab::Abilities::Move do
  helper :tile do |i|
    @tiles ||= Hash.new do |hash, key|
      hash[key] = SmashAndGrab::Tile.new(:grass, nil, 0, key)
    end
    @tiles[i]
  end

  helper(:entity) { @entity ||= Object.new }
  helper(:tiles) { [tile(0), tile(1), tile(2)] }
  helper(:tile_positions) { tiles.map {|t| t.grid_position } }

  subject { SmashAndGrab::Abilities.ability entity, type: :move }

  behaves_like SmashAndGrab::Abilities::Ability

  should "be initialized" do
    subject.owner.should.equal entity 
    subject.can_be_undone?.should.be.true
    subject.skill.should.equal 0
    subject.action_cost.should.equal 0
  end

  should "serialize to json correctly" do
    JSON.parse(subject.to_json).symbolize.should.equal(
        type: :move,
        skill: 0, # TODO: Irrelevant for move?
        action_cost: 0 # TODO: Irrelevant for move? Not sure; perhaps some entities can move OR attack?
    )
  end

  should "generate appropriate action_data" do
    stub(subject.owner).id.returns 12 # Don't know why I need to repeat this.
    path = Object.new
    mock(path).tiles.returns tiles
    mock(path).move_distance.returns 3
    mock(path).last.returns tiles.last
    mock(tiles.last).object.returns nil
    subject.action_data(path).should.equal(
        ability: :move,
        skill: 0, # TODO: Irrelevant for move?
        action_cost: 0, # TODO: Irrelevant for move? Not sure; perhaps some entities can move OR attack?
  
        owner_id: 12,
        movement_cost: 3,
        target_id: nil, # TODO: Irrelevant for move?
        target_position: [0, 2], # TODO: Irrelevant for move?
        path: [[0, 0], [0, 1], [0, 2]]
    )
  end

  describe "#target_valid?" do
    should "if target contains an object" do
      mock(tile(2)).empty?.returns false
      subject.target_valid?(tile(2)).should.be.false
    end

    should "if target is an empty tile without a path" do
      mock(tile(2)).empty?.returns true
      mock(entity).path_to(tile(2)).returns nil
      subject.target_valid?(tile(2)).should.be.false
    end

    should "if target is an empty tile with a path" do
      mock(tile(2)).empty?.returns true
      mock(entity).path_to(tile(2)).returns tiles
      subject.target_valid?(tile(2)).should.be.true
    end
  end

  describe "#do" do
    should "move the entity forwards" do
      mock(entity).move tile_positions, 4
      subject.do action_cost: 0, path: tile_positions, movement_cost: 4
    end
  end

  describe "#undo" do
    should "move the entity backwards" do
      mock(entity).move tile_positions.reverse, -4
      subject.undo action_cost: 0, path: tile_positions, movement_cost: 4
    end
  end
end