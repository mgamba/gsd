module Types
  class QueryType < ::Core::Base::GraphQL::Types::BaseObject
    include ::Core::Jobs::GraphQL::Job::Queries
  end
end