require_relative 'action_history'

class EditorActionHistory < ActionHistory
  def create_action(type, *args); EditorAction.const_get(Inflector.camelize(type)).new *args; end

  def initialize
    super(1000)
  end
end

class EditorAction < Fidgit::History::Action
  class SetTileType < self
    def initialize(tile, new_type)
      @tile, @new_type = tile, new_type
      @old_type = @tile.type
    end

    def do
      @tile.type = @new_type
    end

    def undo
      @tile.type = @old_type
    end
  end

  class SetWallType < self
    def initialize(wall, new_type)
      @wall, @new_type = wall, new_type
      @old_type = @wall.type
    end

    def do
      @wall.type = @new_type
    end

    def undo
      @wall.type = @old_type
    end
  end

  class PlaceObject < self
    def initialize(tile, object_class, type)
      @tile, @object_class, @type = tile, object_class, type
      @old_object = @tile.objects.last
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

  class EraseObject < self
    def initialize(tile)
      @tile = tile
      @object = @tile.objects.last
    end

    def do
      @tile.remove @object
      @tile.map.remove @object
    end

    def undo
      @tile.map << @object
      @tile << @object
    end
  end

  # --------------------------

  include Log

  def can_be_undone?; true; end
end