require 'rails_helper'

describe Test::SeedsController do
  describe '/seed_posts' do
    it 'seeds posts' do
      create(:category)

      expect {
        post :seed_posts, params: { count: 1 }
      }.to change { Post.count }.by 1
    end
  end
end
