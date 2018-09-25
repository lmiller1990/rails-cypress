require 'rails_helper'

describe Test::DatabasesController do
  describe '/clean_database' do
    it 'truncates and seeds the database' do
      post :clean_database

      expect(response.status).to eq 200
      puts response.body
    end
  end
end
