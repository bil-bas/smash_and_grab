module SmashAndGrab
  module Players
    class Player
      attr_reader :faction

      def human?; self.is_a? Human; end
      def ai?; self.is_a? AI; end
      def remote?; self.is_a? Remote; end

      def initialize
        @faction = nil
      end

      def faction=(faction)
        @faction = faction

        @faction.player = self

        @faction.subscribe :turn_ended do
          # Do nothing.
        end
      end

      def update; end
    end
  end
end