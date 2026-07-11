# frozen_string_literal: true

class Module
  def delegate(*method_names, to:)
    method_names.each do |method_name|
      define_method(method_name) do |*args, **kwargs, &block|
        public_send(to).public_send(method_name, *args, **kwargs, &block)
      end
    end
  end
end

require_relative "../lib/stateless/engine"
require_relative "../lib/stateless/transition"
require_relative "../lib/samples/order_state_machine"

RSpec.describe Stateless do
  it "has a version number" do
    expect(Stateless::VERSION).not_to be nil
  end

  describe Samples::OrderStateMachine do
    subject(:state_machine) { described_class.new }

    it "allows an order to be prepared from draft" do
      expect(state_machine.can_transit_to_state?(:draft, :prepared)).to be(true)
      expect(state_machine.transition_event(:draft, :prepared)).to eq(:prepare)

      expect(state_machine.can_transit_by_event?(:draft, :prepare)).to be(true)
      expect(state_machine.transition_state_by_event(:draft, :prepare)).to eq(:prepared)
    end

    it "allows an accepted order to be provisioned and scheduled" do
      expect(state_machine.transition_state_by_event(:accepted, :provision)).to eq(:provisioned)
      expect(state_machine.transition_event(:provisioned, :scheduled)).to eq(:schedule)
    end

    it "allows cancelable states to be canceled" do
      expect(state_machine.can_transit_by_event?(:draft, :cancel)).to be(true)
      expect(state_machine.transition_state_by_event(:partial_payment, :cancel)).to eq(:canceled)
    end

    it "allows transitions configured from every order state" do
      expect(state_machine.transition_state_by_event(:completed, :hold)).to eq(:on_hold)
      expect(state_machine.transition_event(:deposit_requested, :dispatched)).to eq(:dispatch)
    end

    it "rejects transitions that are not configured for the source state" do
      expect(state_machine.can_transit_to_state?(:draft, :provisioned)).to be(false)
      expect(state_machine.transition_event(:draft, :provisioned)).to be_nil

      expect(state_machine.can_transit_by_event?(:prepared, :provision)).to be(false)
      expect(state_machine.transition_state_by_event(:prepared, :provision)).to be_nil
    end
  end
end
