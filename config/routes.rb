Rails.application.routes.draw do
  devise_for :users
  resources :records do
collection do
  get :search
end
  end
  root "records#home"
end
