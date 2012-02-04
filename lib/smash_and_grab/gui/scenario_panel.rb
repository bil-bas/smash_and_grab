module SmashAndGrab
  module Gui
    class ScenarioPanel < Fidgit::Vertical
      def initialize(options = {})
        options = {
            padding: 0,
            spacing: 8,
        }.merge! options
        super options

        label "Smash and Grab!", font_height: 40
        label "Scenario: Bank raid"
      end
    end
  end
end