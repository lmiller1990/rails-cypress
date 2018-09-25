Rails.application.routes.draw do
  resources :posts
  resources :comments

  delete '/clean_database' => 'database_clean', action: :destroy if Rails.env.test?
end
