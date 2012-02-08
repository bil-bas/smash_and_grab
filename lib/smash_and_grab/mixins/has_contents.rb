module SmashAndGrab
  module Mixins
    module HasContents
      attr_reader :contents

      def setup_contents
        # @tmp_contents_id was just a holder until we could do this; can't get it to work unless
        # all objects have been loaded.
        @contents = @tmp_contents_id ? map.object_by_id(@tmp_contents_id) : nil
        log.debug { "#{self} started carrying #{@contents}"} if @contents
        @tmp_contents_id = nil
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