require_relative "../../teststrap"
require_relative "helpers/ability_helper"
describe SmashAndGrab::Abilities::Drop do
  before do
    @entity = Object.new
    @object = Object.new
    @map = Object.new
    @tile = SmashAndGrab::Tile.new(:grass, nil, 1, 2)
  end

  subject { SmashAndGrab::Abilities.ability @entity, type: :drop }

  behaves_like SmashAndGrab::Abilities::Ability

  should "be initialized" do
    subject.owner.should.equal @entity
    subject.can_be_undone?.should.be.true
    subject.skill.should.equal 0
    subject.action_cost.should.equal 1
  end

  should "serialize to json correctly" do
    JSON.parse(subject.to_json).symbolize.should.equal(
        type: :drop,
        skill: 0,
        action_cost: 1
    )
  end

  should "generate appropriate action_data" do
    stub(@entity).id.returns 12
    stub(@object).id.returns 13
    stub(@entity).contents.returns @object
    mock(@entity).tile.stub!.adjacent_tiles(@entity).stub!.find_all(&:empty?).stub!.sample.returns @tile
    subject.action_data.should.equal(
        ability: :drop,
        skill: 0,
        action_cost: 1,

        owner_id: 12,
        target_id: 13,
        target_position: [1, 2],
    )
  end

  describe "#do" do
    should "remove action points and drop object onto the tile" do
      stub(@entity).action_points.returns 1
      mock(@entity).map.stub!.tile_at_grid(1, 2).returns @tile
      mock(@entity).action_points = 0
      mock(@entity).drop @tile

      subject.do action_cost: 1, target_id: 13, target_position: [1, 2]
    end
  end

  describe "#undo" do
    should "give give action points and pick up the object from tile" do
      stub(@object).tile.returns @tile
      stub(@entity).map.stub!.object_by_id(13).returns @object
      stub(@entity).action_points.returns 0
      mock(@entity).action_points = 1
      mock(@entity).pick_up @object

      subject.undo action_cost: 1, target_id: 13, target_position: [1, 2]
    end
  end
end