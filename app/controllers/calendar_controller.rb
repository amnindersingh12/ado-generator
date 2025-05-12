class CalendarController < ApplicationController
  def index
    today = Date.today
    @year = params[:year]&.to_i || today.year
    @month = params[:month]&.to_i || today.month
    @first_day = Date.new(@year, @month, 1)
    @last_day = @first_day.end_of_month
    @attendances_by_day = Attendance.where(in_time: @first_day..@last_day).group_by { |a| a.in_time.to_date }
  end

  def show
    @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    @attendances = Attendance.where(in_time: @date.all_day).includes(:record, :user)
    # Calculate report statistics
    @total_in = @attendances.where.not(in_time: nil).count
    @total_out = @attendances.where.not(out_time: nil).count
    @total_records = @attendances.count
    @unique_users = @attendances.present? ? @attendances.distinct.count(:user_id) : 0
  end

  def day_data
    @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    # Ensure @attendances is not nil and we are getting records for that specific day
    @attendances = Attendance.where(in_time: @date.all_day).includes(:record, :user)

    # Gather the statistics for the tooltip
    @total_in = @attendances.where.not(in_time: nil).count
    @total_out = @attendances.where.not(out_time: nil).count
    @pending_records = @attendances.where(out_time: nil).count
    @unique_users = @attendances.present? ? @attendances.distinct.count(:user_id) : 0
    respond_to do |format|
      format.html { render partial: "calendar/day_tooltip",  locals: { date: @date, attendances: @attendances, total_in: @total_in, total_out: @total_out, pending_records: @pending_records, unique_users: @unique_users }}
      format.js   # if you're using AJAX to render it into a div
    end
end
end
