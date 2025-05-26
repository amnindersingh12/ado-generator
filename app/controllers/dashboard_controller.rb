# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # For "Attendance Summary"
    @total_records = Record.count
    @total_check_ins = Attendance.where.not(in_time: nil).count
    @total_check_outs = Attendance.where.not(out_time: nil).count

    # Data for "Attendance Trends" graph (Manual Implementation)
    # Daily check-ins for the last 7 days

    # 1. Define the date range
    end_date = Time.zone.now.end_of_day # Use Time.zone for consistency
    start_date = (end_date - 6.days).beginning_of_day # 7 days in total including today

    # 2. Fetch attendances within this range that have an in_time
    # We only care about 'in_time' for check-in trends
    attendances_in_range = Attendance.where(in_time: start_date..end_date)

    # 3. Group by date in Ruby and count
    # This creates a hash like: {DateObject => count}
    daily_counts = attendances_in_range
                     .group_by { |attendance| attendance.in_time.to_date }
                     .transform_values(&:count)

    # 4. Prepare data for the chart, ensuring all days in the range are present
    #    with a count of 0 if no attendances, and formatted keys.
    #    This creates a hash like: {"May 20"=>5, "May 21"=>0, ... "May 26"=>10}
    @attendance_trend_data = {}
    (0..6).each do |i|
      current_date = (start_date + i.days).to_date
      formatted_date = current_date.strftime("%b %d") # e.g., "May 26"
      @attendance_trend_data[formatted_date] = daily_counts[current_date] || 0
    end
  end
end
