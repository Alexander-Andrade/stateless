module Samples
  class PaymentStateMachine
    AUTO_APPROVAL_LIMIT_CENTS = 10_000

    attr_reader :engine, :payment

    delegate :can_transit_to_state?, :transition_event, :can_transit_by_event?, :transition_state_by_event, to: :engine

    def initialize(payment)
      @payment = payment
      @engine = ::Stateless::Engine.new(transitions)
    end

    private

    def transitions
      [
        new_transition(
          event_name: :authorize,
          from: %i[pending],
          to: :approved,
          guard: -> { payment.amount_cents <= AUTO_APPROVAL_LIMIT_CENTS }
        ),
        new_transition(
          event_name: :authorize,
          from: %i[pending],
          to: :manual_review,
          guard: -> { payment.amount_cents > AUTO_APPROVAL_LIMIT_CENTS }
        )
      ]
    end

    def new_transition(event_name:, from:, to:, guard:)
      ::Stateless::Transition.new(event_name:, from:, to:, guard:)
    end
  end
end
