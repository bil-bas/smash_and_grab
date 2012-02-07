module Chingu
  class BasicGameObject
    def initialize(options = {})
      @options = options
      @parent = options[:parent]

      # SMASH_AND_GRAB PATCH: Do not want to store this at all.
      #self.class.instances ||= Array.new
      #self.class.instances << self

      #
      # A GameObject either belong to a GameState or our mainwindow ($window)
      #
      @parent = $window.current_scope if !@parent && $window

      # if true, BasicGameObject#update will be called
      @paused = options[:paused] || options[:pause] || false

      # This will call #setup_trait on the latest trait mixed in
      # which then will pass it on to the next setup_trait() with a super-call.
      setup_trait(options)

      setup
    end
  end
end