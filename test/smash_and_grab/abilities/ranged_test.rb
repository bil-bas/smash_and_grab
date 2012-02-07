require_relative "../../teststrap"
require_relative "helpers/ability_helper"

describe SmashAndGrab::Abilities::Ranged do
  before do
    @entity = Object.new
    @enemy = Object.new
    @map = Object.new
    @tile = SmashAndGrab::Tile.new(:grass, nil, 1, 2)
  end

  subject { SmashAndGrab::Abilities.ability @entity, type: :ranged, skill: 5, max_range: 5 }

  behaves_like SmashAndGrab::Abilities::Ability

  should "fail if not given the required arguments" do
    ->{ SmashAndGrab::Abilities.ability @entity, type: :ranged }.should.raise(ArgumentError).message.should.match /no :max_range specified/
  end

  should "be initialized" do
    subject.owner.should.equal @entity
    subject.can_be_undone?.should.be.false
    subject.skill.should.equal 5
    subject.action_cost.should.equal 1
  end

  should "serialize to json correctly" do
    JSON.parse(subject.to_json).symbolize.should.equal(
        type: :ranged,
        skill: 5,
        action_cost: 1,
        min_range: 2,
        max_range: 5
    )
  end

  should "generate appropriate action_data" do
    stub(@entity).id.returns 12
    stub(@enemy).id.returns 13
    stub(@enemy).tile.returns @tile
    stub(@tile).object.returns @enemy
    stub(subject).random_damage.returns 5
    subject.action_data(@enemy).should.equal(
        ability: :ranged,
        skill: 5,
        action_cost: 1,

        owner_id: 12,
        target_id: 13,
        target_position: [1, 2],
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
      stub(@entity).map.stub!.object_by_id(13).returns @enemy
      stub(@entity).action_points.returns 1
      mock(@entity).action_points = 0
      mock(@entity).make_ranged_attack(@enemy, 5)

      subject.do action_cost: 1, target_id: 13, damage: 5 #, target_position: [1, 2]
    end
  end

  describe "#undo" do
    should "give action points and health (if target alive)" do
      stub(@enemy).tile.returns @tile
      stub(@entity).map.stub!.object_by_id(13).returns @enemy
      stub(@entity).action_points.returns 0
      mock(@entity).action_points = 1
      mock(@entity).make_ranged_attack(@enemy, -5)

      subject.undo action_cost: 1, target_id: 13, damage: 5, target_position: [1, 2]
    end

    should "give action points, health and return to map (if target dead)" do
      stub(@enemy).tile.returns nil
      mock(@enemy).tile = @tile
      mock(@entity).make_ranged_attack(@enemy, -5)

      stub(@entity).map do
        stub(@map).object_by_id(13).returns @enemy
        stub(@map).tile_at_grid([1, 2]).returns @tile
        @map
      end
      stub(@entity).action_points.returns 0
      mock(@entity).action_points = 1

      subject.undo action_cost: 1, target_id: 13, damage: 5, target_position: [1, 2]
    end
  end
end