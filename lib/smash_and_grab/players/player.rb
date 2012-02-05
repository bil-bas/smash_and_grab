module SmashAndGrab
module Players
class Player
  attr_reader :faction

  def initialize
    @faction = nil
  end

  def faction=(faction)
    @faction = faction

    @faction.player = self

    @faction.subscribe :turn_started do |faction, entities|
      @active_entities = entities.select(&:alive?).shuffle
    end

    @faction.subscribe :turn_ended do
      @active_entities = nil
    end
  end

  def update; end
end

# Local human player.
class Human < Player
end

# Remote human or AI.
class Remote < Player
end

# Local AI.
class AI < Player
  def update
    if @active_entities.empty?
      faction.end_turn
    else
      return if faction.map.factions.any? {|f| f.entities.any?(&:busy?) }

      # Attempt to attack, else move, else stand around like a loon.
      entity = @active_entities.first
      if entity.alive?
        moves, attacks = entity.potential_moves.partition {|t| t.empty? }

        if attacks.any?
          # TODO: Pick the nearest attack and consider re-attacking.
          path = entity.path_to(attacks.sample)
          faction.map.actions.do :ability, entity.ability(:move).action_data(path.previous_path) if path.requires_movement?
          faction.map.actions.do :ability, entity.ability(:melee).action_data(path.last)
          @active_entities.shift unless entity.ap > 0
        elsif moves.any?
          # TODO: Wait with moves until everyone who can has attacked?
          faction.map.actions.do :ability, entity.ability(:move).action_data(entity.path_to(moves.sample))
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