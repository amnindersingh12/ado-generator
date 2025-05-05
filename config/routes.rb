Rails.application.routes.draw do
  devise_for :users
  resources :records do
    collection do
      get :search
    end
  end
  get "history", to: "records#history"
  root "records#home"
end
