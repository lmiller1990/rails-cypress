module Test
  class DatabasesController < ApplicationController

    skip_before_action :verify_authenticity_token

    def clean_database
      tables = ActiveRecord::Base.connection.tables
      tables.delete 'schema.migrations'
      tables.each { |t| ActiveRecord::Base.connection.execute("TRUNCATE #{t} CASCADE") }

      Rails.application.load_seed unless ['false', false].include?(params['database']['should_seed'])

      render plain: 'Truncated and seeded database'
    end
  end
end
