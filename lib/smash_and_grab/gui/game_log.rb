module SmashAndGrab
  module Gui
    class GameLog < Fidgit::Composite
      include Log

      MAX_ITEMS = 100

      def initialize(state, options = {})
        options = {
            padding: 0,
        }.merge! options

        super options

        @items = []

        @scroll_window = scroll_window width: 420, height: 72, padding: 0 do
          # TODO: Text-area "editable(?)" seem broken. They don't prevent editing while also allowing copy/pasting.
          @text = text_area width: 400, font_height: 14, enabled: false
        end

        @scroll_window.background_color = @text.background_color

        state.subscribe :game_info do |_, text|
          append text
          log.info { "game_info: #{text}" }
        end

        state.subscribe :game_heading do |_, text|
          append "<c=AAAADD> { #{text} }</c>"
          log.info { "game_heading: #{text}" }
        end
      end

      def append(text)
        @items.shift until @items.size < MAX_ITEMS
        @items << text
        @text.text = @items.join "\n"

        @scroll_window.offset_y = Float::INFINITY # Scroll to bottom.
      end
    end
  end
end