# Stateless

`Stateless` is a tiny Ruby finite state machine engine.

It keeps transition rules in plain Ruby objects and leaves model state management
to your application. The engine can answer whether a transition is possible and
what the next state would be, but it does not update your model, run callbacks,
or assume where your current state is stored.

That makes transition logic easy to reuse in service objects, transactions,
background jobs, and other places where model-coupled state machine callbacks can
be too restrictive.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add stateless
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install stateless
```

## Usage

Define transitions as data:

```ruby
transitions = [
  Stateless::Transition.new(event_name: :prepare, from: %i[draft], to: :prepared),
  Stateless::Transition.new(event_name: :schedule, from: %i[provisioned], to: :scheduled),
  Stateless::Transition.new(event_name: :cancel, from: %i[draft scheduled], to: :canceled)
]

state_machine_flow = Stateless::Engine.new(transitions)
```

Ask whether an event can be applied from the current state:

```ruby
transition_possible = state_machine_flow.can_transit_by_event?(order.state, :schedule)
```

Ask which state the event would produce:

```ruby
new_state = state_machine_flow.transition_state_by_event(order.state, :schedule)
order.assign_attributes(state: new_state)
```

You can also query transitions by target state:

```ruby
state_machine_flow.can_transit_to_state?(order.state, :scheduled)
state_machine_flow.transition_event(order.state, :scheduled)
```

## Why Stateless?

`Stateless` is useful when you want transition rules without model-owned state
management.

With callback-heavy state machine gems, transition logic is usually tied to the
model instance and its current state. That can make it harder to choose where
transition side effects run, especially when some work must happen inside a
database transaction and other work must happen after the transaction commits or
inside a background job.

With `Stateless`, the engine only answers questions:

- Can this event be applied from this state?
- What state would this event produce?
- Can this state move to that state?
- Which event moves this state to that state?

Your application decides what to do with those answers.

## Decoupled Transition Handling

Because the next state is returned instead of written automatically, transition
handling can stay explicit:

```ruby
TRANSITION_MAP = {
  schedule: OnScheduleHandler
}.freeze

ANOTHER_TRANSITION_MAP = {
  schedule: AnotherOnScheduleHandler
}.freeze

transition_event = :schedule
transition_possible = state_machine_flow.can_transit_by_event?(order.state, transition_event)
new_state = state_machine_flow.transition_state_by_event(order.state, transition_event)

if transition_possible
  ActiveRecord::Base.transaction do
    order.update!(state: new_state)
    TRANSITION_MAP[transition_event].new(order).call
  end

  ANOTHER_TRANSITION_MAP[transition_event].new(order).call
  SomeSidekiqJob.perform_later(transition_event)
end
```

This keeps the transition table separate from state persistence and side effects.
The current state can live in a database column, in memory, or anywhere else your
application needs it. `Stateless` does not care.

The result is plain Ruby:

- no model callbacks
- no hidden persistence
- no automatic state mutation
- service objects can return values
- background jobs can handle follow-up work
- transaction boundaries stay under your control

## API

### `can_transit_by_event?(from, event_name)`

Returns `true` when `event_name` can be applied from `from`.

```ruby
state_machine_flow.can_transit_by_event?(order.state, :schedule)
```

### `transition_state_by_event(from, event_name)`

Returns the next state after `event_name` is applied from `from`.

```ruby
new_state = state_machine_flow.transition_state_by_event(order.state, :schedule)
order.assign_attributes(state: new_state)
```

### `can_transit_to_state?(from, to)`

Returns `true` when any configured transition can move from `from` to `to`.

```ruby
state_machine_flow.can_transit_to_state?(order.state, :scheduled)
```

### `transition_event(from, to)`

Returns the event name that moves from `from` to `to`.

```ruby
event_name = state_machine_flow.transition_event(order.state, :scheduled)
```

## Sample Order State Machine

See `lib/samples/order_state_machine.rb` for a larger example of an order flow.
It defines transitions such as `prepare`, `provision`, `schedule`, `cancel`,
`reset`, and `reopen`, then delegates the public query methods to
`Stateless::Engine`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
