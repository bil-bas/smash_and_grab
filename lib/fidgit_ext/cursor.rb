module Fidgit
  class Cursor < Chingu::GameObject
    def initialize(options = {})
      super(zorder: ZOrder::GUI, rotation_center: :top_left, image: Image["mouse_cursor.png"])
    end
  end
end