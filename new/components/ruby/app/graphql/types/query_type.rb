module Types
  class QueryType < ::Core::Base::GraphQL::Types::BaseObject
    include ::Core::Jobs::GraphQL::Job::Queries

    include ::GraphQL::User::Queries
    include ::GraphQL::Identity::Queries
    include ::Core::Config::GraphQL::App::Queries
  end
end