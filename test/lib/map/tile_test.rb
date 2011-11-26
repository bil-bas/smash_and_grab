context Tile do
  setup { Tile.new 'grass', nil, 0, 0 }

  context "initial state" do
    asserts(:type).equals 'grass'
    asserts(:x).equals 0
    asserts(:y).equals 0
    asserts(:grid_x).equals 0
    asserts(:grid_y).equals 0
    asserts(:minimap_color).kind_of Gosu::Color
    asserts(:movement_cost).kind_of Integer
    asserts(:image).kind_of Gosu::Image
    asserts(:to_json).equals "\"grass\""
  end
end
