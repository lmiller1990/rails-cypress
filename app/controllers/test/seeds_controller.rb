module Test
  class SeedsController < ApplicationController

    skip_before_action :verify_authenticity_token

    def seed_posts
      category = Category.create!(name: 'ruby')
      count = params[:count] || 0

      count.to_i.times do |c|
        Post.create!(
          title: "Post ##{c}", 
          body: "This is post ##{c}", 
          category: category)
      end
    end
  end
end
