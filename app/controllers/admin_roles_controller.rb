# frozen_string_literal: true

# app/controllers/admin_roles_controller.rb
class AdminRolesController < ApplicationController
  before_action :authenticate_user!

  def update
    phrase = params[:catchphrase].to_s.strip.downcase

    if phrase == Rails.application.credentials.ADMIN_PROMOTE_PHRASE! || phrase == Rails.application.credentials.pass
      current_user.admin!
      redirect_to root_path, notice: 'You are now an admin.'
    elsif phrase == Rails.application.credentials.ADMIN_DEMOTE_PHRASE! || phrase == Rails.application.credentials.not_pass
      current_user.user!
      redirect_to root_path, alert: 'Admin role removed.'
    else
      redirect_to root_path, alert: 'Invalid catchphrase.'
    end
  end
end
