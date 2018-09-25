Rails.application.routes.draw do
  resources :posts
  resources :comments


  namespace :test do
    post 'clean_database', to: 'databases#clean_database'
  end
    #delete '/clean_database', controller: 'test', action: 'clean_database'
    # delete '/clean_database' => 'database_clean', action: :destroy if Rails.env.test?
end
