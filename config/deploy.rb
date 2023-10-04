# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :application, "nabu"
set :repo_url, "git@github.com:nabu-catalog/nabu"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, -> { "/home/deploy/#{fetch :application}" }

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Ruby
set :rbenv_ruby, '3.1.4'

# Rails
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/locks'

# dotenv
append :linked_files, '.env'

# Sentry
set :sentry_api_token, ENV['SENTRY_API_TOKEN']
set :sentry_organization, 'nabu-d0'
set :sentry_project, 'nabu'

set :whenever_roles, [:app]

require 'net/ssh/proxy/command'
set :ssh_options,
    forward_agent: true,
    auth_methods: %w[publickey],
    proxy: Net::SSH::Proxy::Command::new("aws ssm start-session --target i-0f6e289f2b8c5ead5 --document-name AWS-StartSSHSession --parameters 'portNumber=22'")
