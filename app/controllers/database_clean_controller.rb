class DatabaseCleanController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :destroy

  def destroy
    tables = ActiveRecord::Base.connection.tables
    tables.delete 'schema.migrations'
    tables.each { |t| ActiveRecord::Base.connection.execute("TRUNCATE #{t} CASCADE") }

    # If you want to seed
    Rails.application.load_seed
    render plain: 'Truncated and seeded database'
  end
end
