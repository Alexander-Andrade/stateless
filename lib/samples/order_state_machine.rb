module Samples
	class OrderStateMachine
    COMPLETE_STATES = %i[
      draft on_hold declined prepared dispatched assigned accepted provisioned scheduled invoiced canceled partial_payment
    ].freeze
    CANCELABLE_STATES = %i[
      accepted assigned declined draft on_hold provisioned invoiced scheduled partial_payment
    ].freeze
    RESET_STATES = %i[
      draft prepared dispatched assigned accepted provisioned scheduled invoiced canceled
    ].freeze
    UNDISPATCH_STATES = %i[
      draft on_hold prepared dispatched assigned accepted provisioned scheduled invoiced canceled
    ].freeze
    ALL_STATES = %i[
      assigned invoiced completed accepted draft provisioned scheduled prepared confirmed unassigned
      dispatched canceled declined partial_payment deposit_requested partially_refunded refunded on_hold
    ]

    attr_reader :engine

    delegate :can_transit_to_state?, :transition_event, :can_transit_by_event?, :transition_state_by_event, to: :engine

    def initialize
      @engine = ::Stateless::Engine.new(transitions)
    end

    private

    def transitions
    [
      new_transitions(event_name: :accept, from: %i[draft on_hold assigned dispatched], to: :accepted),
      new_transitions(event_name: :assign, from: %i[prepared draft on_hold], to: :assigned),
      new_transitions(event_name: :cancel, from: CANCELABLE_STATES, to: :canceled),
      new_transitions(event_name: :complete, from: COMPLETE_STATES, to: :completed),
      new_transitions(event_name: :decline, from: %i[provisioned], to: :declined),
      new_transitions(event_name: :dispatch, from: ALL_STATES, to: :dispatched),
      new_transitions(event_name: :draft, from: ALL_STATES, to: :draft),
      new_transitions(event_name: :hold, from: ALL_STATES, to: :on_hold),
      new_transitions(event_name: :invoice, from: ALL_STATES, to: :invoiced),
      new_transitions(event_name: :pay_partially, from: ALL_STATES, to: :partial_payment),
      new_transitions(event_name: :prepare, from: %i[draft], to: :prepared),
      new_transitions(event_name: :provision, from: %i[accepted], to: :provisioned),
      new_transitions(event_name: :reject, from: %i[assigned], to: :draft),
      new_transitions(event_name: :reopen, from: %i[completed], to: :accepted),
      new_transitions(event_name: :reprovision, from: %i[declined scheduled], to: :provisioned),
      new_transitions(event_name: :request_deposit, from: ALL_STATES, to: :deposit_requested),
      new_transitions(event_name: :reschedule, from: %i[scheduled], to: :provisioned),
      new_transitions(event_name: :reset, from: RESET_STATES, to: :unassigned),
      new_transitions(event_name: :schedule, from: %i[provisioned], to: :scheduled),
      new_transitions(event_name: :undispatch, from: UNDISPATCH_STATES, to: :draft)
    ]
    end

    def new_transitions(event_name:, from:, to:)
      ::Stateless::Transition.new(event_name:, from:, to:)
    end
	end
end
