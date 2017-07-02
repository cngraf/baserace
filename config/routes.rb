Rails.application.routes.draw do
  root to: 'home#index'

  get    'predict'  => 'home#index'
  post   'predict'  => 'home#predict'
end
