Rails.application.routes.draw do
  devise_for :users
  resources :records do
    member do
      post 'check_in'
      post 'check_out'
    end
    get 'history', on: :member
    collection do
      get :search
    end
  end
  get "history", to: "records#history"
  root "records#home"
end
