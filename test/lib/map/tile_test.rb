require_relative "../../teststrap"

describe Tile do
  subject { described.new :grass, nil, 0, 0 }

  should "have correct initial state" do
    subject.type.should.equal :grass
    subject.x.should.equal 0
    subject.y.should.equal 0
    subject.grid_x.should.equal 0
    subject.grid_y.should.equal 0
    subject.minimap_color.should.be.kind_of Gosu::Color
    subject.movement_cost.should.be.kind_of Integer
    subject.image.should.be.kind_of Gosu::Image
    subject.to_json.should.equal "\"grass\""
  end
end
