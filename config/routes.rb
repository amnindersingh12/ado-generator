# frozen_string_literal: true

Rails.application.routes.draw do
  # Dashboard
  # Setting the root directly makes `root_path` and `dashboard_path` point here.
  root to: 'dashboard#index'
  get "dashboard/index" # This line is functionally redundant if root points here, but can remain for clarity of direct access.

  # Devise authentication
  devise_for :users

  # Record management
  resources :records do
    collection do
      # Keep :search. Consider if :search_records is truly necessary or redundant.
      get :search
      # If 'search_records' serves the exact same purpose as 'search', you can remove the line below.
      # get :search_records
    end

    # Nested attendance routes for a specific record
    resources :attendances, only: [] do # No default RESTful actions for attendance records themselves
      collection do
        # This single endpoint `new_visit` intelligently handles both
        # initiating a new attendance and continuing a pending one.
        get :new_visit, as: :new_visit # GET /records/:record_id/attendances/new_visit

        # These handle form submissions for creating (POST) or updating (PATCH)
        # an attendance record, with the attendance ID passed via the form.
        post :create_or_update_visit
        patch :create_or_update_visit

        # Route to view the attendance history for the associated record.
        get :history
      end
      member do
        # Route to generate and print a pass for a specific attendance record.
        get :print_pass
      end
    end
  end

  # Admin role toggle (via secret catchphrase)
  resource :admin_role, only: [:update] # 'resource' (singular) for routes without an ID

  # Calendar-based attendance history (these routes are well-defined and seem correct)
  get 'history_calendar', to: 'calendar#index'
  get 'history_calendar/:year/:month/:day', to: 'calendar#show', as: :calendar_day
  get 'history_calendar/:year/:month/:day/print', to: 'calendar#print_day', as: :calendar_day_print
  get 'calendar/day_data', to: 'calendar#day_data', as: :calendar_day_data
  get 'monthly_summary', to: 'calendar#monthly_summary', as: :monthly_summary

  # Catch-all route for handling 404 errors (excluding internal Rails engine routes)
  # This should typically be the very last route in your routes.rb file.
  match '*unmatched', to: 'application#not_found', via: :all, constraints: lambda { |req|
    # Excludes standard Rails engine paths from being caught by your 404 handler.
    !req.path.match?(%r{\A/rails/(active_record|active_storage|action_text|conductor)})
  }
end