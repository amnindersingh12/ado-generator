# frozen_string_literal: true

module ErrorHandlers
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::RoutingError, with: :handle_not_found
    rescue_from ActionController::UnknownFormat, with: :handle_not_found
  end

  private

  def handle_not_found(_exception = nil)
    respond_to do |format|
      format.html { render partial: 'shared/not_found', status: :not_found  }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
      format.any  { render plain: '404 Not Found', status: :not_found }
    end
  end
end
