
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
  gem 'factory_bot_rails'
end
```

Install FactoryBot and RSpec.

```
bundle && rails generate rspec:install
``` 

And the mighty webpacker:

```
bundle exec rails webpacker:install && bundle exec rails webpacker:install:vue
```

Update `rails_helper.rb`

```rb
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
