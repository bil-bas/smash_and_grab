require_relative "player"

module SmashAndGrab
  module Players
    # Local AI.
    class AI < Player
      def update
        return if faction.map.busy?

        if @active_entities.empty?
          faction.end_turn
        else
          # Attempt to attack, else move, else stand around like a loon.
          entity = @active_entities.first
          if entity.alive?
            # Try ranged, then charge into melee, then move.
            ranged = entity.potential_ranged.map(&:object).compact.find_all do |object|
              object.is_a?(Objects::Entity) and entity.enemy?(object)
            end

            if ranged.any?
              # Avoid bystanders if there are better opponents.
              unless ranged.all? {|a| a.bystander? }
                ranged.delete_if {|a| a.bystander? }
              end

              entity.use_ability :ranged, ranged.sample
              # Try melee or moving next time.
            else
              moves, attacks = entity.potential_moves.partition {|t| t.empty? }

              if attacks.any?
                # Avoid bystanders if there are better opponents.
                unless attacks.all? {|a| a.object.bystander? }
                  attacks.delete_if {|a| a.object.bystander? }
                end

                # TODO: Pick the nearest attack and consider re-attacking.
                path = entity.path_to(attacks.sample)
                entity.use_ability :move, path.previous_path if path.requires_movement?
                # Only perform melee if you weren't killed by attacks of opportunity.
                target = path.last.object
                entity.add_activity do
                  entity.use_ability :melee, target if entity.alive?
                end

                entity.add_activity do
                  @active_entities.shift unless entity.use_ability?(:melee)
                end

              elsif moves.any?
                # TODO: Wait with moves until everyone who can has attacked?
                entity.use_ability :move, entity.path_to(moves.sample)
                @active_entities.shift
              else
                # Can't do anything at all :(
                # TODO: Maybe wait until other people have tried to move?
                @active_entities.shift
              end
            end
          end
        end
      end
    end
  end
end