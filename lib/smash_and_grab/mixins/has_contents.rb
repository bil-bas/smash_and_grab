module SmashAndGrab
  module Mixins
    module HasContents
      attr_reader :contents

      def setup_contents(data, has_actions)
        if has_actions
          @abilities[:pick_up] = Abilities.ability(self, type: :pick_up)
          @abilities[:drop] = Abilities.ability(self, type: :drop)
        end

        @contents = if data
                      Objects::Static.new map, data
                    else
                      nil
                    end
      end

      def pick_up?(object)
        @contents.nil? and object.pick_up?(self)
      end

      def pick_up(object)
        raise if @contents
        object.tile = nil
        @contents = object
        parent.publish :game_info, "#{colorized_name} picked up #{object.colorized_name}"
        publish :changed
        nil
      end

      def drop(tile)
        raise unless @contents
        object = @contents
        @contents = nil
        parent.publish :game_info, "#{colorized_name} dropped #{object.colorized_name}"
        object.tile = tile
        publish :changed
        nil
      end
    end
  end
end