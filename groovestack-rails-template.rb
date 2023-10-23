# Groovestack Basics
gem 'graphql'
gem 'uuid'
gem 'pg_lock'
gem 'rubocop', require: false
gem 'vite_rails'
gem 'wisper', '>=2.0.0'

# Core Jobs
gem 'que', github: 'talysto/que', branch: 'master'

github 'moonlight-labs/core', branch: 'dev' do
  gem 'core-base'
  gem 'core-jobs'
end

after_bundle do
  
  # for heroku production builds
  run "bundle lock --add-platform x86_64-linux"

  # determine user's package manager
  pkg_manager = ARGV[1].split('=')[1]

  case pkg_manager
  when 'pnpm'
    pkg_command = 'pnpm add'
  when 'yarn'
    pkg_command = 'yarn add'
  when 'npm'
    pkg_command = 'npm install'
  else
    pkg_command = 'pnpm add'
  end
  
  # prevents default behavior for vite to generate `package-lock.json`
  run "touch #{pkg_manager}.lock"

  js_dev_packages = %w[
    ra-data-fakerest
    ra-data-simple-rest
  ]

  js_packages = %w[
    @moonlight-labs/core-config-fe
    @moonlight-labs/core-jobs-fe
    @moonlight-labs/ra-data-graphql-advanced
    @mui/material
    @rails/actioncable
    @react-admin/ra-realtime
    graphql
    graphql-ruby-client
    react
    react-admin
    react-dom
  ]

  # yarn packages
  run "#{pkg_command} #{js_dev_packages.join(' ')}"
  run "#{pkg_command} #{js_packages.join(' ')}"

  # vite installer
  run "bundle exec vite install"

  # config/application.rb
  application "config.active_record.schema_format = :sql"
  application "config.active_job.queue_adapter = :que"
  application "config.action_cable.mount_path = '/cable'"
  application "config.to_prepare do\nRails.autoloaders.main.eager_load_dir(Rails.root.join('app/graphql'))\nend", env: 'development'

  # config/routes.rb
  route "mount ActionCable.server => '/cable'"
  route "post '/graphql', to: 'graphql#execute'"
  route "root to: 'application#index', as: :home"

  # app/javascript/entrypoints
  FileUtils.rm_rf('app/javascript/entrypoints')

  # ./bin/dev
  FileUtils.cp("#{__dir__}/dev", "#{Dir.pwd}/bin/")

  # config/vite.json
  gsub_file "config/vite.json", "app/javascript", "app/frontend"

  # config/initializers/inflections.rb
  insert_into_file "config/initializers/inflections.rb" do
    "ActiveSupport::Inflector.inflections(:en) do |inflect|\n\tinflect.acronym 'GraphQL'\nend"
  end

  # app/controllers/application_controller.rb
  inject_into_file 'app/controllers/application_controller.rb', :before => /^end/ do
    "\n     def index; end\n\n"
  end

  schema_name = "GroovestackSchema"

  # app/graphql/#{schema_name.underscore}.rb
  file "app/graphql/#{schema_name.underscore}.rb" do
    "class #{schema_name} < GraphQL::Schema
      use GraphQL::Subscriptions::ActionCableSubscriptions
      
      mutation(::Types::MutationType)
      query(::Types::QueryType)
      subscription(::Types::SubscriptionType)
    
      # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
      use GraphQL::Dataloader
    
      # GraphQL-Ruby calls this when something goes wrong while running a query:
      def self.type_error(err, context)
        # if err.is_a?(GraphQL::InvalidNullError)
        #   # report to your bug tracker here
        #   return nil
        # end
        super
      end
    
      # Union and Interface Resolution
      def self.resolve_type(abstract_type, obj, ctx)
        # to return the correct GraphQL object type for `obj`
        raise(GraphQL::RequiredImplementationMissingError)
      end
    
      # Stop validating when it encounters this many errors:
      validate_max_errors(100)
    
      # Relay-style Object Identification:
    
      # Return a string UUID for `object`
      def self.id_from_object(object, type_definition, query_ctx)
        # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
        object.to_gid_param
      end
    
      # Given a string UUID, find the object
      def self.object_from_id(global_id, query_ctx)
        # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
        GlobalID.find(global_id)
      end
    end"
  end

  # app/channels/graphql_channel.rb
  file 'app/channels/graphql_channel.rb' do
    "class GraphQLChannel < ::ApplicationCable::Channel
      def subscribed
        @subscription_ids = []
      end
  
      def execute(data)
        query = data['query']
        variables = ensure_hash(data['variables'])
        operation_name = data['operationName']
        context = {
          channel: self,
          schema: ::#{schema_name}
        }
    
        result =  ::#{schema_name}.execute(
          query: query,
          context: context,
          variables: variables,
          operation_name: operation_name
        )
    
        payload = {
          result: result.to_h,
          more: result.subscription?
        }
    
        # Track the subscription here so we can remove it
        # on unsubscribe.
        @subscription_ids << result.context[:subscription_id] if result.context[:subscription_id]
    
        transmit(payload)
      end
  
      def unsubscribed
        @subscription_ids.each do |sid|
          ::#{schema_name}.subscriptions.delete_subscription(sid)
        end
      end
  
    private
  
      def ensure_hash(ambiguous_param)
        case ambiguous_param
        when String
          if ambiguous_param.present?
            ensure_hash(JSON.parse(ambiguous_param))
          else
            {}
          end
        when Hash, ActionController::Parameters
          ambiguous_param
        when nil
          {}
        else
          raise ArgumentError, 'Unexpected parameter: ' + ambiguous_param
        end
      end
    end"
  end

  # app/controllers/graphql_controller.rb
  file "app/controllers/graphql_controller.rb" do
    "class GraphQLController < ApplicationController
      # If accessing from outside this domain, nullify the session
      # This allows for outside API access while preventing CSRF attacks,
      # but you'll have to authenticate your user separately
      # protect_from_forgery with: :null_session

      skip_before_action :verify_authenticity_token

      def execute
        variables = prepare_variables(params[:variables])
        query = params[:query]
        operation_name = params[:operationName]
        context = {
          # Query context goes here, for example:
          # current_user: current_user,
        }
        result =  ::#{schema_name}.execute(query, variables: variables, context: context, operation_name: operation_name)
        render json: result
      rescue StandardError => e
        raise e unless Rails.env.development?
        handle_error_in_development(e)
      end

      private

      # Handle variables in form data, JSON body, or a blank value
      def prepare_variables(variables_param)
        case variables_param
        when String
          if variables_param.present?
            JSON.parse(variables_param) || {}
          else
            {}
          end
        when Hash
          variables_param
        when ActionController::Parameters
          variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
        when nil
          {}
        else
          raise ArgumentError, 'Unexpected parameter: ' + variables_param
        end
      end

      def handle_error_in_development(e)
        logger.error e.message
        logger.error e.backtrace.join('\/n')

        render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
      end
    end"
  end

  # cable.yml
  file "config/cable.yml", force:true do
    {
      development: {
        adapter: 'postgresql',
      },
      test: {
        adapter: 'test',
      },
      production: {
        adapter: 'postgresql',
      }
    }.to_yaml
  end

  # app/frontend/entrypoints/application.js
  file "app/frontend/entrypoints/application.js" do
    "import '~/entrypoints/groovestack-admin.js'"
  end

  # app/views/application/index.html.erb
  file "app/views/application/index.html.erb" do
    "<div id='root'></div>"
  end

  # app/frontend/entrypoints/groovestack-admin.js
  file "app/frontend/entrypoints/groovestack-admin.js" do
    "import React from 'react'

    import { AdminApp } from '../components/AdminApp'
    import { createRoot } from 'react-dom/client'

    const root = createRoot(document.getElementById('root'))
    root.render(React.createElement(AdminApp))"
  end

  # app/frontend/components/AdminApp.tsx
  file "app/frontend/components/AdminApp.tsx" do
    "import React, { useEffect, useState } from 'react'
    import { Admin, Resource } from 'react-admin'
    import { Jobs } from '@moonlight-labs/core-jobs-fe'
    import { HomeView } from '@moonlight-labs/core-config-fe'
    import { initDataProvider } from './dataProvider'
    // import { mockDataProvider } from './mockDataProvider/mock-providers'

    export const AdminApp = () => {
      const [dataProvider, setDataProvider] = useState(null)

      useEffect(() => {
        console.log('init data provider')
        initDataProvider().then((graphQlDataProvider) =>
          setDataProvider(() => graphQlDataProvider),
        )
      }, [])

      if (!dataProvider) return <div>Loading...</div>

      return (
        <Admin
        disableTelemetry
        dataProvider={dataProvider}
        dashboard={HomeView}
      >
          <Resource
            name='Job'
            icon={Jobs.Icon}
            edit={Jobs.Edit}
            list={Jobs.List}
            recordRepresentation={Jobs.resourceRepresentation}
          />
        </Admin>
      )
    }"
  end

  # app/frontend/components/client.ts
  file "app/frontend/components/client.ts" do
    "import { ApolloClient, ApolloLink, HttpLink, InMemoryCache } from '@apollo/client'
    import { createConsumer } from '@rails/actioncable'
    import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'

    // # VITE ENV
    const uri = '/graphql'
      
    const getWSURL = () => {
      return '/cable'
    }

    const cable = createConsumer(getWSURL())

    const hasSubscriptionOperation = ({ query: { definitions } }) => {
      return definitions.some(({ kind, operation }) => kind === 'OperationDefinition' && operation === 'subscription')
    }

    const httpLink = new HttpLink({
      uri
    });

    const link = ApolloLink.split(
      hasSubscriptionOperation,
      new ActionCableLink({ cable, channelName: 'GraphQLChannel' }),
      httpLink
    )

    export const client = new ApolloClient({
      uri,
      cache: new InMemoryCache(),
      link
    })"
  end

  # app/frontend/components/dataProvider.ts
  file "app/frontend/components/dataProvider.ts" do
    "import buildGraphQLProvider from '@moonlight-labs/ra-data-graphql-advanced'

    import { client } from './client'

    export async function initDataProvider(options?: any) {
      return buildGraphQLProvider({
        client,
        fieldNamingConvention: 'snake',
        ...options,
      })
    }"
  end

  # app/graphql/types/query_type.rb
  file "app/graphql/types/query_type.rb" do
    "module Types
      class QueryType < ::Core::Base::GraphQL::BaseObject
        include ::Core::Jobs::GraphQL::Job::Queries
      end
    end"
  end

  # app/graphql/types/mutation_type.rb
  file "app/graphql/types/mutation_type.rb" do
    "module Types
      class MutationType < ::Core::Base::GraphQL::BaseObject
        include ::Core::Jobs::GraphQL::Job::Mutations
      end
    end"
  end

  # app/graphql/types/subscription_type.rb
  file "app/graphql/types/subscription_type.rb" do
    "module Types
      class SubscriptionType < ::Core::Base::GraphQL::BaseObject
        include ::Core::Jobs::GraphQL::Job::Subscriptions
      end
    end"
  end

  # config/puma.rb
  file "config/puma.rb", force:true do
    "# Puma can serve each request in a thread from an internal thread pool.
    # The `threads` method setting takes two numbers: a minimum and maximum.
    # Any libraries that use thread pools should be configured to match
    # the maximum value specified for Puma. Default is set to 5 threads for minimum
    # and maximum; this matches the default thread size of Active Record.
    #
    max_threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }
    min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
    threads min_threads_count, max_threads_count

    # Specifies the `worker_timeout` threshold that Puma will use to wait before
    # terminating a worker in development environments.
    #
    worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

    # Specifies the `port` that Puma will listen on to receive requests; default is 3000.
    #
    port ENV.fetch('PORT') { 3000 }

    # Specifies the `environment` that Puma will run in.
    #
    environment ENV.fetch('RAILS_ENV') { 'development' }

    # Specifies the `pidfile` that Puma will use.
    pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }

    # Specifies the number of `workers` to boot in clustered mode.
    # Workers are forked web server processes. If using threads and workers together
    # the concurrency of the application would be max `threads` * `workers`.
    # Workers do not work on JRuby or Windows (both of which do not support
    # processes).
    #
    # workers ENV.fetch('WEB_CONCURRENCY') { 2 }

    # Use the `preload_app!` method when specifying a `workers` number.
    # This directive tells Puma to first boot the application and load code
    # before forking the application. This takes advantage of Copy On Write
    # process behavior so workers use less memory.
    #
    # preload_app!

    # Allow puma to be restarted by `bin/rails restart` command.
    plugin :tmp_restart

    plugin :que
    plugin :core_cron
    plugin :example_cron_jobs"
  end

  # Procfile.dev
  file "Procfile.dev", force:true do
    "vite: VITE_GQL_ENDPOINT=/graphql bin/vite dev\nweb: bin/rails s"
  end

  # Procfile
  file "Procfile" do
    "web: bin/rails server -p $PORT -e $RAILS_ENV"
  end

  # # # Setup the DB initially
  rails_command "db:create"
  rails_command "db:migrate"

  puts "⚡️ Groovestack App Setup Complete"
end

# these commands required to be run as part of the `bin/rails app:template` command
# if using this template in a `rails new with template` command, these lines should be commented 
run_bundle 
run_after_bundle_callbacks