module Fidgit
  class Cursor < Chingu::GameObject
    def update
      self.x, self.y = $window.mouse_x / 4, $window.mouse_y / 4

      super

      nil
    end
  end
end