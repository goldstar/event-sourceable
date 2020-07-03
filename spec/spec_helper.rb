require "bundler/setup"
#require "event-sourceable"

ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '../../../spec/dummy_app'

unless File.exist?(File.expand_path("dummy_app/config/database.yml", __dir__))
  warn "No database.yml detected for the dummy app, please run `rake prepare` first"
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require File.expand_path('../spec/dummy_app/config/environment.rb', __dir__)
require 'rspec/rails'

# Migrate
migrations_path = Pathname.new(File.expand_path("dummy_app/db/migrate", __dir__))
puts migrations_path
ActiveRecord::MigrationContext.new(migrations_path, ActiveRecord::Base.connection.schema_migration).migrate