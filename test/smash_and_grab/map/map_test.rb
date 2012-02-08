require_relative "../../teststrap"

describe SmashAndGrab::Map do
  helper :objects_data do
    [
        {
            "class" => "entity",
            "type" => "professor_goggles",
            "id" => 0,
            "health" => 5,
            "contents" => nil,
            "movement_points" => 7,
            "action_points" => 2,
            "facing" => "left",
            "tile" => [
                1,
                0
            ],
        },
        {
            "class"  => "object",
            "type" => "tree",
            "id" => 1,
            "tile" => [
                0,
                1
            ]
        }
    ]
  end

  helper :walls_data do
    [
        {
            "type" => "low_fence",
            "tiles" => [
                [
                    0,
                    0
                ],
                [
                    0,
                    1
                ]
            ]
        }
    ]
  end

  helper :tiles_data do
    [
        ['grass', 'concrete'],
        ['dirt', 'dirt'],
    ]
  end

  helper :map_data do
    {
        'tiles' => tiles_data,
        'objects' => objects_data,
        'actions' => [],
        'walls' => walls_data
    }
  end

  subject { SmashAndGrab::Map.new map_data.symbolize }

  describe "#tile_at_grid" do
    should "find the correct tile" do
      subject.tile_at_grid(0, 0).type.should.equal :grass
      subject.tile_at_grid(1, 0).type.should.equal :concrete
    end
    
    should "return nil for positions outside the grid" do
      subject.tile_at_grid(-1, 0).should.be.nil
      subject.tile_at_grid(2, 0).should.be.nil
    end
  end

  describe "#tile_at_position" do
    should "find the correct tile" do
      subject.tile_at_position(0, 0).type.should.equal :grass
      subject.tile_at_position(4, 8).type.should.equal :dirt
    end

    should "return nil outside the grid" do
      subject.tile_at_position(-8, -8).should.be.nil
      subject.tile_at_position(64, 0).should.be.nil
    end
  end

  describe "#objects" do
    should "give correct object" do
      subject.object_by_id(0).id.should.equal 0
      subject.object_by_id(1).id.should.equal 1
    end

    should "raise error with bad id" do
      ->{ subject.object_by_id(-1) }.should.raise(RuntimeError)
      ->{ subject.object_by_id(2) }.should.raise(RuntimeError)
    end
  end

  describe "#save_data" do
    subject { SmashAndGrab::Map.new(map_data.symbolize).save_data }

    should "contain the same data as was loaded" do
      subject[:version].should.equal SmashAndGrab::VERSION
      subject[:map_size].should.equal [2, 2]
      JSON.parse(subject[:tiles].to_json).should.equal tiles_data
      JSON.parse(subject[:walls].to_json).should.equal walls_data
      JSON.parse(subject[:objects].to_json).should.equal objects_data
    end
  end
end
