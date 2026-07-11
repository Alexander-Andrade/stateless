module Stateless
  class Engine
    attr_reader :transitions

    def initialize(transitions)
      @transitions = transitions
    end

    def can_transit_to_state?(from, to)
      transitions.any? { |transition| target_transition_by_state?(transition, from, to) }
    end

    def transition_event(from, to)
      transition = transitions.detect { |transition| target_transition_by_state?(transition, from, to) }
      transition&.event_name
    end

    def can_transit_by_event?(from, event_name)
      transitions.any? { |transition| target_transition_by_event?(transition, from, event_name) }
    end

    def transition_state_by_event(from, event_name)
      transition = transitions.detect { |transition| target_transition_by_event?(transition, from, event_name) }
      transition&.to
    end

    private

    def target_transition_by_state?(transition, from, to)
      transition.from.include?(from.to_sym) &&
        transition.to == to.to_sym &&
        (transition.guard.nil? || transition.guard.call)
    end

    def target_transition_by_event?(transition, from, event_name)
      transition.event_name.to_sym == event_name.to_sym &&
        transition.from.include?(from.to_sym) &&
        (transition.guard.nil? || transition.guard.call)
    end
  end
end