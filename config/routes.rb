# frozen_string_literal: true

Rails.application.routes.draw do
  get "dashboard/index"
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
      get 'print_pass', on: :member
      get 'new_check_out', on: :member
      post 'create_check_out', on: :member
      get 'complete_check_in', on: :member
      patch 'update_check_in', on: :member
    end
  end

  # Admin role toggle (via secret catchphrase)
  resource :admin_role, only: [:update]

  # Calendar-based attendance history
  get 'history_calendar', to: 'calendar#index'
  get 'history_calendar/:year/:month/:day', to: 'calendar#show', as: :calendar_day
  get 'history_calendar/:year/:month/:day/print', to: 'calendar#print_day', as: :calendar_day_print
  get 'calendar/day_data', to: 'calendar#day_data', as: :calendar_day_data
  get 'monthly_summary', to: 'calendar#monthly_summary', as: :monthly_summary

  # Root path
  get 'dashboard', to: 'dashboard#index', as: :dashboard # This creates dashboard_path

  root to: 'dashboard#index'

  # Catch-all route for handling 404 errors (excluding internal Rails engine routes)
  match '*unmatched', to: 'application#not_found', via: :all, constraints: lambda { |req|
    !req.path.match?(%r{\A/rails/(active_record|active_storage|action_text|conductor)})
  }
end
