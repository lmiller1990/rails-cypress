
```
rails new cypress_app -T --database=postgresql
```

Add FactoryBot and RSpec and webpacker.

```rb
gem 'webpacker', '~> 3.5'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 3.8'
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
```

Install FactoryBot and RSpec.

```
bundle && rails generate rspec:install && mkdir spec/system
``` 

And the mighty webpacker:

```
bundle exec rails webpacker:install && bundle exec rails webpacker:install:vue
```

Update `rails_helper.rb`

```rb
require 'webdrivers'

# ...

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

While you are there, remove this line:

```rb
config.fixture_path = "#{::Rails.root}/spec/fixtures"
```

Create the database:

```sh
rails db:create
```

Ok, now we are ready.

```
rails g model category name:string && \
rails g model post title:string body:text category:references && \
rails db:migrate
```

Create the controllers:

```
touch app/controllers/posts_controller.rb && \
touch app/controllers/comments_controller.rb
```

And in `models/category.rb` add:

```rb
class Category < ApplicationRecord
  has_many :posts
end 
```

Update routes:

```rb
Rails.application.routes.draw do
  resources :posts
  resources :comments
end
```

Add some code to `app/controllers/posts_controller.rb`:

```rb
class PostsController < ApplicationController
  def new
  end
end
```

Create some views with 

```sh
touch app/views/posts/new.html.erb` && \
touch app/views/posts/_form.html.erb` && \
touch app/views/posts/show.html.erb` && \
touch app/views/posts/index.html.erb` && \
touch app/views/posts/edit.html.erb`
```

Create a test:

```sh
touch spec/system/creates_a_post_spec.rb
```

And add:

```rb
require 'rails_helper'

feature 'creates a post', type: :system, js: true do
  it 'creates a post' do
    visit new_post_url
    take_screenshot

    expect(1).to eq 1
  end
end
```

That was a lot of work. Make sure everything is working by running `rspec spec/system/creates_a_post_spec.rb`. If the test passes, it's time to do some real work.
