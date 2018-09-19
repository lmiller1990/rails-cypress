require 'rails_helper'

feature 'creates a post', type: :system, js: true do
  let!(:category) { create(:category) }

  context 'the post is valid' do
    it 'creates a post' do
      visit new_post_url

      fill_in 'post_title', with: 'my great post'
      fill_in 'post_body', with: 'body'
      select category.name, from: 'post[category_id]'
      click_on 'Create Post'

      Post.all.reload

      expect(Post.count).to eq 1
      expect(Post.first.title).to eq 'my great post'
      expect(page).to have_content('my great post')
    end
  end

  context 'the post in not vald' do
    it 'displays a flash message' do
      visit new_post_url

      fill_in 'post_title', with: 'a'
      fill_in 'post_body', with: 'body'
      select category.name, from: 'post[category_id]'
      click_on 'Create Post'

      Post.all.reload

      expect(Post.count).to eq 0
      expect(page).to have_content('too short')
    end
  end
end
