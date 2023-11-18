# NOTE: to disable oauth, uncomment the line below

# Core::Config::App.dynamic_config << { key: :oauth_enabled, build: Proc.new { false } }

Core::Config::App.dynamic_config << { key: :hashed_ra_login_path, build: Proc.new { '#/login' } }