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
  end
end