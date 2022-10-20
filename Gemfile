source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.13'

# Databases
gem 'mysql2'
gem 'graphql'
gem "graphiql-rails"

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.2'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# gem 'libv8', '<4'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]


# Views
gem 'compass-rails'
gem 'haml-rails'
gem 'to-csv', :require => 'to_csv'
gem 'kaminari'
gem 'oai'
gem 'analytical'

# Admin
gem 'country-select'
gem 'activeadmin'
gem 'bootstrap-sass'

# Authentications
gem 'devise', '2.2.3'
gem 'cancancan', '~> 1.13.1'

# Database improvements
gem 'rails_or'
gem 'squeel'
gem 'nilify_blanks'

# Search
gem 'sunspot_rails'
gem 'sunspot_solr'

# Media Detection
gem 'ruby-filemagic'

# Deployment
gem 'capistrano'
gem 'capistrano-unicorn'
gem 'capistrano-rbenv'

# Logging
gem 'rollbar'
gem 'newrelic_rpm'

# Misc
gem 'progress_bar'
gem 'paper_trail', '~> 3'
gem 'quiet_assets'
gem 'roo', '~> 2.1.0'
# Unpublished version used for ability to use StringIO. https://github.com/roo-rb/roo-xls/pull/7
gem 'roo-xls', :git => 'https://github.com/roo-rb/roo-xls', :ref => '0a5ef88'
gem 'streamio-ffmpeg'
gem 'rake', '< 11.0'
gem 'timeliness'

# Image processing
gem 'rmagick'

# Scheduling
gem 'whenever', :require => false

# Background processing
gem 'delayed_job_active_record'
gem 'daemons'

group :development, :test do
  gem 'test-unit'
  gem 'turn', '~> 0.8.3', :require => false
  gem 'rspec-rails', '~> 3.0'
  gem 'thin'

  gem 'spring'
  gem 'spring-commands-rspec'

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'letter_opener'

  # Guard
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'guard-sunspot'

  gem 'rb-inotify', :require => RUBY_PLATFORM.include?('linux') ? 'rb-inotify' : false
  gem 'rb-fsevent', :require => RUBY_PLATFORM.include?('darwin') ? 'rb-fsevent' : false
end

group :development do
  gem 'annotate'
  gem 'binding_of_caller'
  gem 'better_errors'
  gem 'traceroute' # Helps find unused routes and controller actions
  gem 'rubocop'
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'launchy'
end
