module SmashAndGrab
  module Gui
    class ObjectPanel < Fidgit::Horizontal
      def initialize(object, options = {})
        options = {
            padding: 0,
            spacing: 8,
        }.merge! options

        super options

        @object = object

        vertical padding: 0 do
          # TODO: Clicking on portrait should center.
          @portrait = image_frame @object.image, padding: 0, background_color: Color::GRAY,
                                  factor: (@object.is_a?(Objects::Vehicle) ? 0.25 : 1)

          @changed_event = @object.subscribe :changed do
            @portrait.image = @object.image
          end
        end

        vertical padding: 0, spacing: 4 do
          @name = label @object.name

          Fidgit::Vertical.new padding: 0, spacing: 0 do
            scroll_window width: 350, height: 72 do
              text_area text: "#{@object.name} once was a pomegranate, but it got better... " * 10,
                        background_color: Color::NONE, width: 330, font_height: 14, editable: false
            end
          end
        end
      end

      def finalize
        @changed_event.unsubscribe
      end
    end
  end
end