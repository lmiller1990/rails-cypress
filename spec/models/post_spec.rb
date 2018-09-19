require 'rails_helper'

RSpec.describe Post, type: :model do
  let!(:category) { create(:category) }

  it 'title contains at least 5 characters' do
    post = build(:post, title: 'a' * 4, category: category)

    expect(post.valid?).to be false
  end
end
