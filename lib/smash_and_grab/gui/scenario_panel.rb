require_relative "game_log"

module SmashAndGrab
  module Gui
    class ScenarioPanel < Fidgit::Vertical
      def initialize(state, options = {})
        options = {
            padding: 0,
            spacing: 8,
        }.merge! options
        super options

        label "Scenario: Bank raid"

        horizontal padding_h: 4, padding_v: 0 do
          @game_log = GameLog.new(state, parent: self)
        end
      end

      def finalize
        # Don't need to clean up.
      end
    end
  end
end