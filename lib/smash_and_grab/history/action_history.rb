module SmashAndGrab
class ActionHistory < Fidgit::History
  extend Forwardable

  DATA_ACTIONS = 'actions'

  def_delegators :@actions, :empty?

  def completed_turns; @actions.count {|a| a.is_a? GameActions::EndTurn }; end

  # Perform a History::Action, adding it to the history.
  # If there are currently any actions that have been undone, they will be permanently lost and cannot be redone.
  #
  # @param [History::Action] action Action to be performed
  def do(*args)
    raise ArgumentError, "Needs one or more params" if args.empty?

    action = if args.size > 1 or args.first.is_a? Symbol
      create_action(*args)
    else
      args.first
    end

    raise ArgumentError, "Parameter, 'action', expected to be a #{Action}, but received: #{action}" unless action.is_a? Action

    # Remove all undone actions when a new one is performed.
    if can_redo?
      if @last_done == -1
        @actions.clear
      else
        @actions = @actions[0..@last_done]
      end
    end

    # If history is too big, remove the oldest action.
    if @actions.size >= @max_size
      @actions.shift
    end

    @last_done = @actions.size
    @actions << action
    action.do

    nil
  end

  def can_undo?
    super and @actions[@last_done].can_be_undone?
  end

  def to_json(*a)
    # Only save actions that have been performed. Discard the redo-list.
    if @last_done >= 0
      @actions[0..@last_done].to_json(*a)
    else
      [].to_json(*a)
    end
  end
end
end