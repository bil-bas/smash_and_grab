require_relative "entity_panel"
require_relative "object_panel"
require_relative "scenario_panel"

module SmashAndGrab
  module Gui
    # The info panel contains scenario/entity/object panels based what is selected.
    class InfoPanel < Fidgit::Vertical
      attr_reader :object

      def initialize(state, options = {})
        options = {
            padding: 4,
            background_color: Color::BLACK,
        }.merge! options
        super options

        @show_info = false

        @frame = vertical padding: 4, background_color: Color.rgb(0, 0, 150), width: 440, height: 112

        @scenario_panel = ScenarioPanel.new state
        self.object = nil

        self.x, self.y = ($window.width - width) / 2, $window.height - height
      end

      def object=(object)
        return if defined? @object and object == @object

        @frame.each(&:finalize)

        @frame.clear
        case object
          when Objects::Entity
            panel = EntityPanel.new(object, @show_info, parent: @frame)
            panel.subscribe :info_toggled do |_, shown|
              @show_info = shown
            end
          when Objects::Static, Objects::Vehicle
            ObjectPanel.new(object, parent: @frame)
          when nil
            @frame.add @scenario_panel
          else
            raise object.inspect
        end

        @object = object
      end
    end
  end
end
