require 'csv'

class DashboardController < ApplicationController
  def index
    @total_records = Record.count
    @total_check_ins = Attendance.where.not(in_time: nil).where.not(out_time: nil).count
    @total_check_outs = Attendance.where.not(out_time: nil).where.not(in_time: nil).count
    @pending_check_outs = Attendance.where(out_time: nil).where.not(in_time: nil).count

    timeframe = params[:timeframe] || 'week' # Default to week

    case timeframe
    when 'day'
      date_range = Date.today.all_day
      @daily_attendance_labels = [Date.today.strftime('%a, %b %d')]
    when 'week'
      date_range = 7.days.ago.to_date.upto(Date.today)
      @daily_attendance_labels = date_range.map { |date| date.strftime('%a, %b %d') }
    when 'month'
      date_range = 30.days.ago.to_date.upto(Date.today) # Typo: should be upto
      @daily_attendance_labels = date_range.map { |date| date.strftime('%a, %b %d') }
    end

    # Corrected date_range for month
    date_range = 30.days.ago.to_date.upto(Date.today) if timeframe == 'month'

    @daily_attendance_data = {}
    date_range.each do |date|
      formatted_date = date.strftime('%a, %b %d')
      @daily_attendance_data[formatted_date] = {
        in: Attendance.where('DATE(in_time) = ?', date).count,
        out: Attendance.where('DATE(out_time) = ?', date).count
      }
    end
    @daily_check_in_values = @daily_attendance_data.values.map { |v| v[:in] }
    @daily_check_out_values = @daily_attendance_data.values.map { |v| v[:out] }


      # Data for the peak check-in/out times (last 24 hours)
    @peak_time_data_in = {}
    @peak_time_data_out = {}
    current_time_local = Time.zone.now.floor(1.hour) # Use Time.zone.now for time zone awareness

    24.times do |i|
      hour_local = current_time_local - i.hours
      formatted_time = hour_local.strftime('%H:%M')
      start_of_hour = hour_local.beginning_of_hour.utc # Convert to UTC for database query if stored in UTC
      end_of_hour = hour_local.end_of_hour.utc       # Convert to UTC for database query if stored in UTC

      @peak_time_data_in[formatted_time] = Attendance.where('in_time BETWEEN ? AND ?', start_of_hour, end_of_hour).count
      @peak_time_data_out[formatted_time] = Attendance.where('out_time BETWEEN ? AND ?', start_of_hour, end_of_hour).count
    end
    @peak_time_labels = @peak_time_data_in.keys.reverse
    @peak_time_in_values = @peak_time_data_in.values.reverse
    @peak_time_out_values = @peak_time_data_out.values.reverse



    # --- POPULATING NEW INSTANCE VARIABLES FOR CSV ---

    # @daily_records: All individual attendance records for the CSV
    # Assuming you want all attendance records, or perhaps filtered by a relevant timeframe
    # For a comprehensive report, let's fetch all relevant attendances with their associated records and users
    @daily_records = Attendance.includes(:record, :user).order(created_at: :asc)
    # If you want to filter these by the same timeframe as the charts, you'd add:
    # @daily_records = Attendance.where(created_at: date_range).includes(:record, :user).order(created_at: :asc)

    # @daily_attendance_summary: This is already populated by @daily_attendance_data, so no change needed here.
    # The generate_csv method uses @daily_attendance_summary, which is a hash of formatted_date => {in: count, out: count}
    # Your @daily_attendance_data is already in this format, so you can just assign it:
    @daily_attendance_summary = @daily_attendance_data

    # @user_activity_summary: Data for User Activity Analysis
    # This will group attendances by user and calculate summary statistics
    @user_activity_summary = {}
    Attendance.includes(:user).each do |attendance|
      user_email = attendance.user&.email || 'Unknown User'
      @user_activity_summary[user_email] ||= { total_actions: 0, first_check_in: nil, last_check_out: nil }

      @user_activity_summary[user_email][:total_actions] += 1 # Increment for each attendance record

      @user_activity_summary[user_email][:first_check_in] = attendance.in_time if attendance.in_time && (@user_activity_summary[user_email][:first_check_in].nil? || attendance.in_time < @user_activity_summary[user_email][:first_check_in])

      next unless attendance.out_time

      @user_activity_summary[user_email][:last_check_out] = attendance.out_time if @user_activity_summary[user_email][:last_check_out].nil? || attendance.out_time > @user_activity_summary[user_email][:last_check_out]
    end

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv, filename: "attendance_data_#{Date.today}.csv" }
      format.pdf do
        render pdf: "attendance_report_#{Date.today}",
               template: 'dashboard/attendance_report',
               layout: 'pdf',
               disposition: 'inline'
      end
    end
  end

  private

  def generate_csv
    CSV.generate(headers: true) do |csv|
      # --- Detailed Daily Attendance Records ---
      csv << ['--- Detailed Daily Attendance Records ---']
      csv << ['Date', 'User Email', 'Check-In Time', 'Check-Out Time', 'Hours Spent', 'Record Created At']

      @daily_records.each do |record| # This now iterates over Attendance objects
        hours_spent = nil
        hours_spent = ((record.out_time - record.in_time) / 1.hour).round(2) if record.in_time && record.out_time

        csv << [
          record.in_time&.to_date,
          record.user&.email, # Assuming you have a user association on Attendance model
          record.in_time&.strftime('%Y-%m-%d %H:%M:%S'),
          record.out_time&.strftime('%Y-%m-%d %H:%M:%S'),
          hours_spent,
          record.created_at&.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end

      csv << [] # Add a blank line for better readability

      # --- Summary of Daily Check-In/Out Counts ---
      csv << ['--- Summary of Daily Check-In/Out Counts ---']
      csv << ['Date', 'Total Check-In Count', 'Total Check-Out Count']
      @daily_attendance_summary.each do |date, counts|
        csv << [date, counts[:in], counts[:out]]
      end

      csv << [] # Add a blank line

      # --- User Activity Analysis ---
      csv << ['--- User Activity Analysis ---']
      csv << ['User Email', 'Total Check-In/Out Actions', 'First Check-In', 'Last Check-Out']

      @user_activity_summary.each do |email, summary|
        csv << [
          email,
          summary[:total_actions],
          summary[:first_check_in]&.strftime('%Y-%m-%d %H:%M:%S'),
          summary[:last_check_out]&.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end

      csv << [] # Add a blank line

      # --- Peak Time Analysis ---
      csv << ['--- Peak Time Analysis ---']
      csv << ['Time (Hour)', 'Peak Check-In Count', 'Peak Check-Out Count']
      @peak_time_labels.each_with_index do |time, index|
        csv << [time, @peak_time_in_values[index], @peak_time_out_values[index]]
      end
    end
  end
end
