class EditorAction::PlaceObject < EditorAction
  def initialize(tile, object_class, type)
    @tile, @object_class, @type = tile, object_class, type
    @old_object = @tile.object
  end

  def do
    if @old_object
      @tile.remove @old_object
      @tile.map.remove @old_object
    end

    @new_object = @object_class.new @tile.map,
                                 'type' => @type,
                                 'tile' => @tile.grid_position,
                                 'facing' => :right
  end

  def undo
    @tile.remove @new_object
    @tile.map.remove @new_object

    if @old_object
      @tile.map << @old_object
      @tile << @old_object
    end
  end
end