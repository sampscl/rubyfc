Rails.application.routes.draw do
  get 'home', to: 'home#index'

  resources :fleet_logs
  resources :missions
  resources :fleets
  resources :fleet_rankings
  resources :leagues
  resources :tournaments
  resources :users
  resources :games
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
