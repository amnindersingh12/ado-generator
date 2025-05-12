Rails.application.routes.draw do
  devise_for :users
  resources :records do
    get :search, on: :collection
    resources :attendances do
      get :history, on: :collection
    end
  end
  resource :admin_role, only: [ :update ]

  get "history_calendar", to: "calendar#index"
  get "history_calendar/:year/:month/:day", to: "calendar#show", as: :calendar_day
  get "calendar/day_data", to: "calendar#day_data", as: :calendar_day_data

  root to: "records#index"
end
