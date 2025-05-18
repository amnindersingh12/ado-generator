Rails.application.routes.draw do
  # Devise authentication
  devise_for :users

  # Record management
  resources :records do
    collection do
      get :search
    end

    # Nested attendance routes
    resources :attendances do
  get 'history', on: :collection
      get 'new_check_out', on: :member
      post 'create_check_out', on: :member
      get 'complete_check_in', on: :member
      patch 'update_check_in', on: :member
    end
  end

  # Admin role toggle (via secret catchphrase)
  resource :admin_role, only: [ :update ]

  # Calendar-based attendance history
  get "history_calendar", to: "calendar#index"
  get "history_calendar/:year/:month/:day", to: "calendar#show", as: :calendar_day
  get "calendar/day_data", to: "calendar#day_data", as: :calendar_day_data

  # Root path
  root to: "records#index"

  # Catch-all route for handling 404 errors (excluding internal Rails engine routes)
  match "*unmatched", to: "application#not_found", via: :all, constraints: lambda { |req|
    !req.path.match?(/\A\/rails\/(active_record|active_storage|action_text|conductor)/)
  }
end
