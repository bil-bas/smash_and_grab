module SmashAndGrab
  module Mixins
    module LineOfSight
      #
      def line_of_sight?(tile)
        !line_of_sight_blocked_by(tile)
      end

      # Returns the tile that blocks sight, otherwise nil.
      # Implements 'Bresenham's line algorithm'
      def line_of_sight_blocked_by(target_tile)
        start_tile = tile

        # Check for the special case of looking diagonally.
        x1, y1 = tile.grid_x, tile.grid_y
        x2, y2 = target_tile.grid_x, target_tile.grid_y

        step_x = x1 < x2 ? 1 : -1
        step_y = y1 < y2 ? 1 : -1
        dx, dy = (x2 - x1).abs, (y2 - y1).abs

        if dx == dy
          # Special case of the diagonal line.
          (dx - 1).times do
            x1 += step_x
            y1 += step_y

            # If the centre tile is blocked, then we don't work.
            tile = @map.tile_at_grid(x1, y1)
            if tile.blocks_sight?
              #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::RED
              return tile
            else
              #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::BLUE
            end
          end
        else
          # General case, ray-trace.
          error = dx - dy

          # Ensure that all tiles are visited that the sight-line passes over,
          # not just those that create a "drawn" line.
          dx *= 2
          dy *= 2

          length = ((dx + dy + 1) / 2)

          (length - 1).times do
            # Note that this ignores the special case of error == 0
            if error > 0
              error -= dy
              x1 += step_x
            else
              error += dx
              y1 += step_y
            end

            tile = @map.tile_at_grid(x1, y1)
            if tile.blocks_sight?
              #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::RED
              return tile
            else
              #Tile.blank.draw_rot tile.x, tile.y, ZOrder::TILE_SELECTION, 0, 0.5, 0.5, 1, 1, Color::BLUE
            end
          end
        end

        nil # Didn't hit anything.
      end
    end
  end
end