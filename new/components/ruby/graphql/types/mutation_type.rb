module Types
  class MutationType < ::Core::Base::GraphQL::Types::BaseObject
    include ::Core::Jobs::GraphQL::Job::Mutations
  end
end