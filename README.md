Traditionally, Rails gives us a full stack development framework including E2E tests with Selenium to develop websites. Let's see how to transition an app using Rails' built in system tests to using cypress.io, a new E2E framework built on Node.js, targetting modern JavaScript heavy applications.

A common Rails stack looks like:

- RSpec for the testing framework
- FactoryBot for populating the database
- DatabaseCleaner (or just ActiveRecord) for cleaning the database between tests
- Selenium for driving the browser in E2E tests

Moving to cypress.io (at least for the E2E tests), it now looks like:

- Mocha/Chai combo for the testing framework
- No good replacement for FactoryBot
- Need to figure the database clearing/truncation out on our own
- cypress.io for the browser tests

At first glance, and based on my experience, the stack is a lot less "batteries included", which is what I like about Rails. I'm continuing to try new things out. This article will

1. Set up the traditional stack, and make a simple CRUD app with a few simple E2E tests
2. Move to the cypress.io stack, while implementing the same tests
3. Dicuss improvements and thoughts

I like each blog post to be independant, and include all the steps to recreate it. If you don't care about setting up the Rails app with RSpec etc, just grab the repo here and move to the second half.

## Creating the Rails App

Generate the Rails app, skipping MiniTest and using postgres for the database with `rails new cypress_app -T --database=postgresql`. Update `group :development, :test` in the `Gemfile`:

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
end
```

Then run `bundle install`, and generate the binstub and `system` folder by running:

```
rails generate rspec:install && mkdir spec/system
``` 

Next. update `rails_helper.rb` to let us use `FactoryBot` methods directly in our specs. Also, we want to use `selenium_chrome_headless` for the specs (before moving to cypress.io):

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

Create a test:

```sh
touch spec/system/posts_spec.rb
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

That was a lot of work. Make sure everything is working by running `rspec spec/system`. If the test passes, everything is working correctly.

## E2E with Rails' System Tests

Before moving on to using cypress.io, let's make sure the code is working correctly using the built in system tests, which run using `selenium_chrome_headless`. Update `spec/system/posts_spec.rb`:

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

We included a flash message validating the minimum length of a post - we will add this validation in a momnet. First, update `app/views/posts/new.html.erb`:

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

Now we have a boring, yet working and well tested Rails app, let's proceed to add Cypress and migrate our test suite. Firstly, install Cypress and a few dependecies with:

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

ss: cypress_1

Furthermore, a `cypress` folder was created for you.

## A Creates Post Test

Let's migrate the first test - creating a post succesfully - to Cypress. Create the test with `touch cypress/integration/posts.spec.js`, and add the following:

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

The Cypress DSL is fairly easy to read. Strictly speaking, `{force: true}` should not be necessary. Some of my tests were randomly failing to find the element, though, so I added it. I'll investigate this in more detail later.

If you still have the Cypress UI open, search for the test using the search box:

ss: cypress_3

This fails, of course:

ss: cypress_2

Because no categories exist. Before implementing a nice work around, just create one by dropping down into `rails console` and running `Category.create!(name: 'ruby')`. Now the test passes!

cypress_4

There are some problems:

1. Running the tests in the development env is not good. We should use `RAILS_ENV=test`.
2. Need a way to seed some data, like a category.
3. Should clean the database between each test.

Let's get to work on the first two. 

## Running in RAILS_ENV=test
