module Fidgit
  module Event
    # Returned by {#subscribe} and can be used to {#unsubscribe}
    class Subscription
      attr_reader :publisher, :event, :handler

      def initialize(publisher, event, handler)
        @publisher, @event, @handler = publisher, event, handler
      end

      def unsubscribe
        @publisher.unsubscribe self
      end
    end

    class << self
      def new_event_handlers
        # Don't use Set, since it is not guaranteed to be ordered.
        Hash.new {|h, k| h[k] = [] }
      end
    end

    # @return [Subscription] Definition of this the handler created by this subscription, to be used with {#unsubscribe}
    def subscribe(event, method = nil, &block)
      raise ArgumentError, "Expected method or block for event handler" unless !block.nil? ^ !method.nil?
      raise ArgumentError, "#{self.class} does not handle #{event.inspect}" unless events.include? event

      @_event_handlers ||= Event.new_event_handlers
      handler = method || block
      @_event_handlers[event] << handler

      Subscription.new self, event, handler
    end

    # @overload unsubscribe(subscription)
    #   Unsubscribe from a #{Subscription}, as returned from {#subscribe}
    #   @param subscription [Subscription]
    #   @return [Boolean] true if the handler was able to be deleted.
    #
    # @overload unsubscribe(handler)
    #   Unsubscribe from first event this handler has been used to subscribe to..
    #   @param handler [Block, Method] Event handler used.
    #   @return [Boolean] true if the handler was able to be deleted.
    #
    # @overload unsubscribe(event, handler)
    #   Unsubscribe from specific handler on particular event.
    #   @param event [Symbol] Name of event originally subscribed to.
    #   @param handler [Block, Method] Event handler used.
    #   @return [Boolean] true if the handler was able to be deleted.
    #
    def unsubscribe(*args)
      @_event_handlers ||= Event.new_event_handlers

      case args.size
        when 1
          case args.first
            when Subscription
              # Delete specific event handler.
              subscription = args.first
              raise ArgumentError, "Incorrect publisher for #{Subscription}: #{subscription.publisher}" unless subscription.publisher == self
              unsubscribe subscription.event, subscription.handler
            when Block, Method
              # Delete first events that use the handler.
              handler = args.first
              !!@_event_handlers.find {|_, handlers| handlers.delete handler }
            else
              raise TypeError, "handler must be a #{Subscription}, Block or Method: #{args.first}"
          end
        when 2
          event, handler = args
          !!@_event_handlers[event].delete(handler)
        else
          raise ArgumentError, "Requires 1..2 arguments, but received #{args.size} arguments"
      end
    end
  end
end