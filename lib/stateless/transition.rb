require 'dry-struct'

module Stateless
  Types = Dry.Types()

  class Transition < Dry::Struct
    attribute :event_name, Types::Coercible::Symbol
    attribute :from, Types::Array.of(Types::Coercible::Symbol)
    attribute :to, Types::Coercible::Symbol
    attribute :guard, Types::Instance(Proc).optional.default(nil)
  end
end
