ruby = Category.create!(name: 'ruby')
javascript = Category.create!(name: 'javascript')

Post.create!(title: 'Seed Post', body: 'This is a seed post.', category: ruby)
