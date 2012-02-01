require_relative "../../teststrap"

context Map do
  helper :objects_data do
    [
        {
            "class" => "entity",
            "type" => "professor_goggles",
            "id" => 0,
            "health" => 8,
            "movement_points" => 7,
            "action_points" => 1,
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

  setup { Map.new map_data }

  context "#tile_at_grid" do
    asserts("for a grid position left of grid") { topic.tile_at_grid(-1, 0) }.nil
    asserts("for a grid position right of grid") { topic.tile_at_grid(2, 0) }.nil
    asserts("for a grid position in grid is correct tile") { topic.tile_at_grid(0, 0).type }.equals 'grass'
  end

  context "#tile_at_position" do
    asserts("for a screen position outside grid") { topic.tile_at_position(64, 0) }.nil
    asserts("for a screen position in grid is correct tile") { topic.tile_at_position(0, 0).type }.equals 'grass'
  end

  context "#objects" do
    asserts("given negative object id").raises(RuntimeError) { topic.object_by_id(-1) }
    asserts("given object id too high").raises(RuntimeError) { topic.object_by_id(2) }
    asserts("given id 0 gives object whose id") { topic.object_by_id(0).id }.equals 0
    asserts("given id 1 gives object whose id") { topic.object_by_id(1).id }.equals 1
  end

  context "#save_data" do
    setup { topic.save_data }

    asserts("version") { topic['version'] }.equals SmashAndGrab::VERSION
    asserts("map size") { topic['map_size'] }.equals [2, 2]
    asserts("tiles correct") { JSON.parse(topic['tiles'].to_json) == tiles_data }
    asserts("walls correct") { JSON.parse(topic['walls'].to_json) == walls_data }
    asserts("objects correct") { JSON.parse(topic['objects'].to_json) == objects_data }
  end
end
