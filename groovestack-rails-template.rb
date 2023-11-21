# Groovestack Basics
gem 'graphql'
gem 'uuid'
gem 'pg_lock'
gem 'rubocop', require: false
gem 'vite_rails'
gem 'wisper', '>=2.0.0'
require 'json'

# Core Jobs
gem 'que', github: 'talysto/que', branch: 'master'
gem 'omniauth-rails_csrf_protection'

github 'talysto/groovestack-core', branch: 'main' do
  gem 'core-base'
  gem 'core-config'
  gem 'core-auth'
  gem 'core-jobs'
end

after_bundle do

  pkg_manager = ARGV[1]

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
    @apollo/client
    @groovestack/base
    @groovestack/config
    @groovestack/auth
    @groovestack/jobs
    @moonlight-labs/ra-data-graphql-advanced
    @mui/material
    @rails/actioncable
    graphql
    graphql-ruby-client
    react
    react-admin
    react-dom
  ]

  # vite installer
  run "bundle exec vite install"

  # packages
  run "#{pkg_command} #{js_dev_packages.join(' ')}"
  run "#{pkg_command} #{js_packages.join(' ')}"

  # config/application.rb
  application "config.active_record.schema_format = :sql"
  application "config.active_job.queue_adapter = :que"
  application "config.action_cable.mount_path = '/cable'"
  application "config.to_prepare do\nRails.autoloaders.main.eager_load_dir(Rails.root.join('app/graphql'))\nend", env: 'development'
  # application "config.require_master_key = true", env: 'production'
  gsub_file "config/environments/production.rb", "# config.require_master_key = true", "config.require_master_key = true"

  # config/routes.rb
  route "mount ActionCable.server => '/cable'"
  route "post '/graphql', to: 'graphql#execute'"
  route "mount Core::Auth::Railtie, at: ''"
  route "root to: 'application#index', as: :home"

  # app/javascript/entrypoints
  FileUtils.rm_rf('app/javascript/entrypoints')

  # ./bin/dev
  FileUtils.cp("#{__dir__}/dev", "#{Dir.pwd}/bin/")

  # config/vite.json
  gsub_file "config/vite.json", "app/javascript", "app/frontend"

  # config/initializers/inflections.rb addition
  insert_into_file "config/initializers/inflections.rb" do
    "ActiveSupport::Inflector.inflections(:en) do |inflect|\n\tinflect.acronym 'GraphQL'\nend"
  end

  # app/controllers/application_controller.rb addition
  inject_into_file 'app/controllers/application_controller.rb', :before => /^end/ do
    "\n\tdef index; end\n\n"
  end

  inject_into_file 'app/channels/application_cable/connection.rb', :after => "ActionCable::Connection::Base\n" do
    "\t\tinclude Core::Auth::ActionCable::Connection\n"
  end

  file_json = JSON.parse(File.read("#{__dir__}/new/file-config.json"))

  file_json.each do |fileRef|
    file_contents = File.read("#{__dir__}/#{fileRef["location"]}")
  
    file "#{fileRef["write_location"]}" do
      "#{file_contents}"
    end
  end

  # cable.yml overwrite
  file "config/cable.yml", force: true do
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

  # app/frontend/entrypoints/application.js overwrite
  file "app/frontend/entrypoints/application.js" do
    "import '~/entrypoints/groovestack-admin.js'"
  end

  # app/views/application/index.html.erb overwrite
  file "app/views/application/index.html.erb" do
    "<div id='root'></div>"
  end

  # config/puma.rb overwrite
  file "config/puma.rb", force: true do
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

  # Procfile.dev overwrite
  file "Procfile.dev", force: true do
    "vite: VITE_GQL_ENDPOINT=/graphql bin/vite dev\nweb: bin/rails s -p 3000"
  end

  # # # Setup the DB initially
  rails_command "db:create"
  rails_command "db:migrate"

  puts "⚡️ Groovestack App Setup Complete"
end

# these commands required to be run as part of the `bin/rails app:template` command except in the case of 7.1+
# if Rails.gem_version <= Gem::Version.new('7.1')
  run_bundle
  run_after_bundle_callbacks
# end


# [Start]==========Rails multi environment credentials==========

run "EDITOR=cat rails credentials:edit --environment development"
run "EDITOR=cat rails credentials:edit --environment production"

# [End]==========Rails multi environment credentials==========