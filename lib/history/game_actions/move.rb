class GameAction::Move < GameAction
  DATA_PATH = 'path'
  DATA_ID = 'entity_id' # Ignored when reading.
  DATA_MOVEMENT_COST = 'movement_cost'

  def initialize(map, data)
    @map = map

    case data
      when MovePath
        @mover = data.mover
        @path = data.tiles
        @movement_cost = data.move_distance
        @time = Time.now
      when Hash
        @mover = map.object_by_id(data[DATA_ID])
        @path = data[DATA_PATH].map {|x, y| @map.tile_at_grid(x, y) }
        @movement_cost = data[DATA_MOVEMENT_COST]
        @time = data[DATA_TIME]
      else
        raise data.to_s
    end
  end

  def do
    @mover.move(@path[1..-1], @movement_cost)
  end

  def undo
    @mover.move(@path.reverse[1..-1], -@movement_cost)
  end

  def save_data
    {
      DATA_ID => @mover.id,
      DATA_PATH => @path.map(&:grid_position),
      DATA_MOVEMENT_COST => @movement_cost,
    }
  end
end