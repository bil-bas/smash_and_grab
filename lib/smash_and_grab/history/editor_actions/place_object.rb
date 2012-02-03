module SmashAndGrab
module EditorActions
class PlaceObject < EditorAction
  def initialize(tile, new_object_class, type)
    @tile, @object_class, @type = tile, new_object_class, type
    @old_object = @tile.object
  end

  def do
    # TODO: Should remove all objects under the object being placed, not just the one at the tile of placement.
    if @old_object
      @old_object_tile = @old_object.tile
      @old_object.tile = nil
      @tile.map.remove @old_object
    end

    @new_object = @object_class.new @tile.map,
                                 type: @type,
                                 tile: @tile.grid_position,
                                 facing: :left
  end

  def undo
    @new_object.tile = nil
    @tile.map.remove @new_object

    if @old_object
      @tile.map << @old_object
      @old_object.tile = @old_object_tile
    end
  end
end
end
end