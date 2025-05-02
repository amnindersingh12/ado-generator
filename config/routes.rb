Rails.application.routes.draw do
  devise_for :users
  resources :records, only: [:index, :show, :new, :create, :destroy]
  root "pages#home"
end
