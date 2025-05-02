class PagesController < ApplicationController
  def home
    @records = Record.all.order(created_at: :desc)
    

  end
end
