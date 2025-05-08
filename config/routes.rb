Rails.application.routes.draw do
  devise_for :users
  resources :records do
    get :search, on: :collection
    resources :attendances do
      get :history, on: :collection
    end
  end
  root to: "records#index"
end
