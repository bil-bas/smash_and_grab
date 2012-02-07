require_relative "../path"

module SmashAndGrab
  module Mixins
    module Pathfinding
      # Returns a list of tiles this entity could move to (including those they could melee at) [Set]
      def potential_moves
        destination_tile = tile # We are sort of working backwards here.

        # Tiles we've already dealt with.
        closed_tiles = Set.new
        # Tiles we've looked at and that are in-range.
        valid_tiles = Set.new
        # Paths to check { tile => path_to_tile }.
        open_paths = { destination_tile => Paths::Start.new(destination_tile, destination_tile) }

        melee_cost = has_ability?(:melee) ? ability(:melee).action_cost : Float::INFINITY

        while open_paths.any?
          path = open_paths.each_value.min_by(&:cost)
          current_tile = path.last

          open_paths.delete current_tile
          closed_tiles << current_tile

          exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
          exits.each do |wall|
            testing_tile = wall.destination(current_tile)
            object = testing_tile.object

            if object and object.is_a?(Objects::Entity) and enemy?(object)
              # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
              if (current_tile.empty? or current_tile == tile) and ap >= melee_cost
                valid_tiles << testing_tile
              end

            elsif testing_tile.passable?(self) and (object.nil? or object.passable?(self))
              new_path = Paths::Move.new(path, testing_tile, wall.movement_cost)

              # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
              if new_path.move_distance <= movement_points
                old_path = open_paths[testing_tile]
                if old_path
                  if new_path.move_distance < old_path.move_distance
                    open_paths[testing_tile] = new_path
                  end
                else
                  open_paths[testing_tile] = new_path
                  valid_tiles << testing_tile if testing_tile.empty?
                end
              end
            end
          end
        end

        valid_tiles
      end

      # A* path-finding.
      def path_to(destination_tile)
        return Paths::None.new if destination_tile == tile
        return Paths::Inaccessible.new(destination_tile) unless destination_tile.passable?(self)

        closed_tiles = Set.new # Tiles we've already dealt with.
        open_paths = { tile => Paths::Start.new(tile, destination_tile) } # Paths to check { tile => path_to_tile }.

        destination_object =  destination_tile.object
        destination_is_enemy = (destination_object and destination_object.is_a? Objects::Entity and destination_object.enemy?(self))

        melee_cost = has_ability?(:melee) ? ability(:melee).action_cost : Float::INFINITY

        while open_paths.any?
          # Check the (expected) shortest path and move it to closed, since we have considered it.
          path = open_paths.each_value.min_by(&:cost)
          current_tile = path.last

          return path if current_tile == destination_tile

          open_paths.delete current_tile
          closed_tiles << current_tile

          next if path.is_a? Paths::Melee

          # Check adjacent tiles.
          exits = current_tile.exits(self).reject {|wall| closed_tiles.include? wall.destination(current_tile) }
          exits.each do |wall|
            testing_tile = wall.destination(current_tile)

            new_path = nil

            object = testing_tile.object
            #if testing_tile.zoc?(faction) and not (testing_tile == destination_tile or destination_is_enemy)
            #  # Avoid tiles that have zoc, unless at the end of the path. You have to MANUALLY enter.
            #  next
            if object and object.is_a?(Objects::Entity) and enemy?(object)
              # Ensure that the current tile is somewhere we could launch an attack from and we could actually perform it.
              if (current_tile.empty? or current_tile == tile) and ap >= melee_cost
                new_path = Paths::Melee.new(path, testing_tile)
              else
                next
              end
            elsif testing_tile.passable?(self)
              if object.nil? or object.passable?(self)
                new_path = Paths::Move.new(path, testing_tile, wall.movement_cost)
              else
                next
              end
            end

            # If the path is shorter than one we've already calculated, then replace it. Otherwise just store it.
            old_path = open_paths[testing_tile]
            if old_path
              if new_path.move_distance < old_path.move_distance
                open_paths[testing_tile] = new_path
              end
            else
              open_paths[testing_tile] = new_path
            end
          end
        end

        Paths::Inaccessible.new(destination_tile) # Failed to connect at all.
      end
    end
  end
end