Traditionally, Rails gives us a full stack development framework including E2E tests with Selenium to develop websites. Let's see how to transition an app using Rails' built in system tests to using Cypress, a new E2E framework built on Node.js, targetting modern JavaScript heavy applications.

A common Rails stack looks like:

- RSpec for the testing framework
- FactoryBot for populating the database
- DatabaseCleaner (or just ActiveRecord) for cleaning the database between tests
- Selenium for driving the browser in E2E tests

Moving to Cypress (at least for the E2E tests), it now looks like:

- Mocha/Chai combo for the testing framework
- No good replacement for FactoryBot
- Need to figure the database clearing/truncation out on our own
- Cypress for the browser tests

At first glance, and based on my experience, the stack is a lot less "batteries included", which is what I like about Rails. I'm continuing to try new things out. This article will

1. Set up the traditional stack, and make a simple CRUD app with a few simple E2E tests
2. Move to the cypress.io stack, while implementing the same tests
3. Dicuss improvements and thoughts

I like each blog post to be independant, and include all the steps to recreate it. If you don't care about setting up the Rails app with RSpec etc, just grab the repo here and move to the second half.

## Creating the Rails App

Note: If you want to skip to the section where I add Cypress, ctrl+f "Installing and Setting Up Cypress".

Generate the Rails app, skipping MiniTest and using Postgres for the database with `rails new cypress_app -T --database=postgresql`. Update `group :development, :test` in the `Gemfile`:

Add FactoryBot and RSpec and webpacker.

```rb
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'rspec-rails', '~> 3.8'
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'rack-cors'
end
```

Then run `bundle install`, and generate the binstub and `system` folder by running:

```
rails generate rspec:install && mkdir spec/system
``` 

Next. update `rails_helper.rb` to let us use `FactoryBot` methods directly in our specs. Also, we want to use `selenium_chrome_headless` for the specs (before moving to Cypress):

```rb
require 'webdrivers'

# ...

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # ...

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end


```

Initalize the database with `rails db:create`. That should have set up RSpec, FactoryBot and installed the dependencies for system tests.

## Creating the Crud App

We will make a simple blog app, that lets an anonymous user create a post, which has a `title`, `body` and `category`. We need a `Post` and `Category` model - create them with the following:

```
rails g model category name:string && \
rails g model post title:string body:text category:references && \
rails db:migrate
```

Next, we need a `posts_controller` to create posts. Create one with `touch app/controllers/posts_controller.rb`. We will come back to this in a moment.

Update `models/category.rb` to reflect the `has_many` relationship (a category can have many posts):

```rb
class Category < ApplicationRecord
  has_many :posts
end 
```

Update `config/routes.rb`:

```rb
Rails.application.routes.draw do
  resources :posts
end
```

Add some code to `app/controllers/posts_controller.rb`:

```rb
class PostsController < ApplicationController
  def new
  end

  def create
  end

  def index
  end
end
```

Create some views with 

```sh
mkdir app/views/posts && \
touch app/views/posts/new.html.erb && \
touch app/views/posts/_form.html.erb && \
touch app/views/posts/show.html.erb && \
touch app/views/posts/index.html.erb
```

Create a test with `touch spec/system/posts_spec.rb`, and add:

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

Make sure everything is working by running `rspec spec/system`. If the test passes, everything is working correctly.

## E2E with Rails' System Tests

Before moving on to using Cypress, let's make sure the code is working correctly using the built in system tests, which run using `selenium_chrome_headless`. Update `spec/system/posts_spec.rb`:

```rb
require 'rails_helper'

feature 'Posts', type: :system, js: true do
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
end
```

This fails with:

```
Failures:

  1) Posts the post is valid creates a post
     Failure/Error: fill_in 'post_title', with: 'my great post'

     Capybara::ElementNotFound:
       Unable to find field "post_title"
```

Update `app/controllers/posts_controller.rb` first:

```rb
class PostsController < ApplicationController
  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to @post
    else
      flash[:errors] = @post.errors.full_messages
      render :new
    end
  end

  def show
    @post = Post.find params[:id]
  end

  def index
    @posts = Post.all
  end

  private

  def post_params 
    params.require(:post).permit(:title, :body, :category_id)
  end
end
```

Now we need the views. Start with `app/views/posts/_form.html.erb`:

```rb
<% if flash.present? %>
  <% flash[:errors].each do |msg| %>
    <%= content_tag :div, msg %>
  <% end %>
<% end %>

<%= form_with model: @post, local: true do |f| %>
  <%= f.label :title %>
  <%= f.text_field :title %>

  <%= f.label :body %>
  <%= f.text_area :body %>

  <%= f.select :category_id do %>
    <%= options_from_collection_for_select(Category.all, :id, :name) %>
  <% end %>

  <%= f.submit %>
<% end %>
```

We included a flash message validating the minimum length of a post - we will add this validation in a moment. First, update `app/views/posts/new.html.erb`:

```rb
<%= render partial: 'form' %>
```

And lastly, `app/views/posts/show.html.erb`:

```rb
<h2><%= @post.title %></h2>

<div class="category">
  Category: <%= @post.category.name %>
</div>

<div class="body">
  <%= @post.body %>
</div>
```

Now running `rspec spec/system` should give us a passing test. Let's implement two more tests, starting with validating the length of a post title. Update `app/models/post.rb`.

```rb
class Post < ApplicationRecord
  validates :title, { length: { minimum: 5 } } 
  belongs_to :category
end
```

Next, update `spec/system/posts_spec.rb`:

```
context 'the post title is too short' do
  it 'displays a flash' do
    visit new_post_url

    fill_in 'post_title', with: 'aaa'
    fill_in 'post_body', with: 'body'
    select category.name, from: 'post[category_id]'
    click_on 'Create Post'

    Post.all.reload

    expect(Post.count).to eq 0
    expect(page).to have_content('too short')
  end
end
```

This should pass, too.

Finally, add the following to `app/views/posts/index.html.erb`: 

```erb
<h3>Posts</h3>

<div class="posts">
  <% @posts.each do |post| %>
    <div class="post">
      <div class="title">
        Title: <%= post.title %>
      </div>

      <div class="body">
        Body<%= post.title %>
      </div>
      
      <%= link_to 'edit', edit_post_url(post) %>
      <hr>
    </div>
  <% end %>
</div>
```

This shows a list of posts at `/posts`. Lastly, a test in `spec/system/posts_spec.rb`:

```rb
it 'shows a list of posts' do
  5.times { create(:post, category: category) }

  visit posts_url

  expect(all('.post').length).to eq 5
end
```

Running `rspec spec/system` should yield three passing tests.

## Installing and Setting Up Cypress

Now we have a boring, yet working and well tested Rails app. Let's proceed to add Cypress and migrate our test suite. Firstly, install Cypress and a few dependecies with:

```sh
yarn add cypress axios --dev
```

Next, following their [documentation](https://docs.cypress.io/guides/getting-started/installing-cypress.html#Adding-npm-scripts), add a command to `package.json`. Mine `package.json` looks like this:

```json
{
  "name": "cypress_app",
  "private": true,
  "dependencies": {},
  "devDependencies": {
    "axios": "^0.18.0",
    "cypress": "^3.1.0"
  },
  "scripts": {
    "cypress:open": "cypress open"
  }
}
```

Finally, run `yarn cypress:open`. You should see:

![](https://user-images.githubusercontent.com/19196536/46187267-c1f00280-c31d-11e8-9eaf-59844f46baef.png)

Furthermore, a `cypress` folder was created for you.

## A Creates Post Test

Let's migrate the first test - creating a post succesfully - to Cypress. First, start the rails server by running `rails server` in a separate terminal from Cypress. Next, create the test with `touch cypress/integration/posts.spec.js`, and add the following:

```js
const context = describe

describe('Creates a post', () => {
  context('the post is valid', () => {
    it('redirects to the created post', () => {
      cy.visit('localhost:3000/posts/new')

      cy.get('#post_title').type('my post', {force: true})
      cy.get('#post_body').type('this is the post body', {force: true})
      cy.get('#post_category_id').select('ruby', {force: true})

      cy.get('input[type="submit"]').click()

      cy.get('.category').contains('Category: ruby')
    })
  })
})
```

The Cypress DSL is fairly easy to read. Strictly speaking, `{force: true}` should not be necessary. Some of my tests were randomly failing without this, though, so I added it. I'll investigate this in more detail later.

If you still have the Cypress UI open, search for the test using the search box:

![](https://user-images.githubusercontent.com/19196536/46187265-c1f00280-c31d-11e8-8b67-0193827354e5.png)

This fails, of course:

![](https://user-images.githubusercontent.com/19196536/46187266-c1f00280-c31d-11e8-8122-7583ff289024.png)

Because no categories exist. Before implementing a nice work around, just create one by dropping down into `rails console` and running `Category.create!(name: 'ruby')`. Now the test passes!

![](https://user-images.githubusercontent.com/19196536/46187264-c1576c00-c31d-11e8-8795-961f4ebfdb53.png)

There are some problems:

1. Running the tests in the development env is not good. We should use `RAILS_ENV=test`.
2. Need a way to seed some data, like a category.
3. Should clean the database between each test.

Let's get to work on the first two. 

## Test Seed Data and Running in RAILS_ENV=test

Let's set up some basic seed data for the tests to use. First, create a `seeds` folder containing a `test.rb` file by running `mkdir db/seeds && touch db/seeds/test.rb`. Inside, add:

```rb
ruby = Category.create!(name: 'ruby')
javascript = Category.create!(name: 'javascript')

Post.create!(title: 'Seed Post', body: 'This is a seed post.', category: ruby)
```

Next, in `db/seeds.rb` add:

```rb
load(Rails.root.join( 'db', 'seeds', "#{Rails.env.downcase}.rb"))
```

This will seed the correct seed file based on the current `RAILS_ENV`. 

## Cleaning the Database between Tests

Now we have a way to seed data, but no way to clean the database after each test. The way I've been handling this is by making a POST request to dedicated `/test//clean_database` endpoint __before__ each test, as [recommended by Cypress](https://docs.cypress.io/guides/references/best-practices.html#Using-after-or-afterEach-hooks). Let's make that API. First, update `config/routes.rb`:

```rb
Rails.application.routes.draw do

  # ...

  if Rails.env.test?
    namespace :test do
      post 'clean_database', to: 'databases#clean_database'
      post 'seed_posts', to: 'seeds#seed_posts'
    end
  end
end
```

Next create the controller and spec: `mkdir app/controllers/test && touch app/controllers/test/databases_controller.rb` and `mkdir spec/controllers && mkdir spec/controllers/test && touch spec/controllers/test/databases_controller_spec.rb`.

Starting with `databases_controller_spec.rb`, add the following:

```rb
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
```

There are two functions this API provides. Both specs test for truncation. We also allow a `should_seed` parameter to be provided. If `should_seed` is true, then we repopulate the database using the data defined in `db/seeds/test.rb`.

The controller implementation is as follows:

```rb
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
```

This should yield two passing specs. Now, restart the Rails server with `RAILS_ENV=test rails server`. Now, we need a way to actually access the API from within Cypress. Inside of `cypress/support/commands.js`, add the following:

```js
import axios from 'axios'

Cypress.Commands.add('cleanDatabase', (opts = { seed: true }) => {
  return axios({
    method: 'POST',
    url: 'http://localhost:3000/test/clean_database',
    data: { should_seed: opts.seed }
  })
})
```

Cypress automatically loads all the helpers in `commands.js` for us. 

Since Rails is running on port 3000, and Cypress is assigned an arbitrary port, we need to support CORS for the `/test` routes. Inside `config/environments/test.rb`, add the following:

```rb
if Rails.env.test?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '/test/*', headers: :any, methods: %i(post)
    end
  end
end
```

This allows CORS for the test environment only. Restart the Rails server, and reopen the Cypress UI if you closed it. It should pass... alas, it does not. 

If you look closely, only on the initial opening of the Cypress UI, the browser kind of "flickers" once. For some reason, this causes the `beforeEach` hook to be called twice, messing up the seed data. The post request contains the category id of the first seed run, however since the browser flickers and causes the data to be reseeded, the initial category id used in the test no longer exists! 

Once you have the UI running, however, simply rerunning the test should be enough to pass. Typically I only open the UI once, and leave it open, so it is not a big deal locally. On CI, this is a huge problem though. I'm going to get in contact with the Cypress team and see if they have a work around.

One last thing I want to add is the ability to seed some data, depending on the test. For this, I'll use another test-env-only controller. Create it with `touch app/controllers/test/seeds_controller.rb`. Add a test with `touch spec/controllers/test/seeds_controller_spec.rb`. Add the following test:

```rb
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
```

This endpoint will simply seed a specified number posts. Now, the implementation in `seeds_controller.rb`:

```rb
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
```

This test should pass. Here are two more tests - one for the case where a post title is too short, and an error is displayed, and another for the `/posts` index page. This once will make use of the new `/seed_posts` route, so update `commands.js`:

```
Cypress.Commands.add('seedPosts', (count) => {
  return axios({
    method: 'POST',
    url: 'http://localhost:3000/test/seed_posts',
    data: { count }
  })
})
```

Everything passes! 

![](https://user-images.githubusercontent.com/19196536/46187263-c1576c00-c31d-11e8-9357-8e1089396cef.png)

## Conclusion and Thoughts

This was a very long article. We covered:

- Setting up a traditional Rails app
- Installing Cypress
- Creating specific route for cleaning and seeding the database
- Using Cypress hooks, such as `beforeEach`, and custom commands

Cypress is certainly a great tool, and a refreshing new angle on E2E testing. The lack of support for non Chromium based browsers, and of information on how to integrate it with various backends led to some challenges. However, I'm positive Cypress is going in a good direction and will continue to refine my workflow and integration with Rails.
