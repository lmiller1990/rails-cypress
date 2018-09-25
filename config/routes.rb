Rails.application.routes.draw do
  resources :posts
  resources :comments


  namespace :test do
    post 'clean_database', to: 'databases#clean_database'
    post 'seed_posts', to: 'seeds#seed_posts'
  end
end
