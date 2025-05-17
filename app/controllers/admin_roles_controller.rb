# app/controllers/admin_roles_controller.rb
class AdminRolesController < ApplicationController
  before_action :authenticate_user!

  def update
    phrase = params[:catchphrase].to_s.strip.downcase

    if phrase ==  ENV["ADMIN_PROMOTE_PHRASE"]
      current_user.admin!
      redirect_to root_path, notice: "You are now an admin."
    elsif phrase == ENV["ADMIN_DEMOTE_PHRASE"]
      current_user.user!
      redirect_to root_path, alert: "Admin role removed."
    else
      redirect_to root_path, alert: "Invalid catchphrase."
    end
  end
end


