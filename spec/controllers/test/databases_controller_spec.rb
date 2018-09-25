require 'rails_helper'

describe Test::DatabasesController do
  describe '/clean_database' do
    it 'truncates and seeds the database' do
      category = create(:category)
      5.times { |i| create(:post, category: category) }

      post :clean_database, params: { 'database': { 'should_seed': true } }

      # Seed db/seeds/test for default seeds
      # Default 2 categories and 1 post
      expect(Post.count).to eq 1
      expect(Category.count).to eq 2
    end

    it 'truncates and seeds the database' do
      category = create(:category)
      5.times { |i| create(:post, category: category) }

      post :clean_database, params: { 'database': { 'should_seed': false } }
 
      expect(Post.count).to eq 0
      expect(Category.count).to eq 0
    end
  end
end
