class DashboardController < ApplicationController
  def index
    @total_records = Record.count
    @total_check_ins = Attendance.where.not(in_time: nil).count
    @total_check_outs = Attendance.where.not(out_time: nil).count
    @pending_check_outs = Attendance.where(out_time: nil).count

    timeframe = params[:timeframe] || 'week' # Default to week

    case timeframe
    when 'day'
      date_range = Date.today.beginning_of_day..Date.today.end_of_day
      @daily_attendance_labels = [Date.today.strftime('%a, %b %d')]
    when 'week'
      date_range = 7.days.ago.to_date.upto(Date.today)
      @daily_attendance_labels = date_range.map { |date| date.strftime('%a, %b %d') }
    when 'month'
      date_range = 30.days.ago.to_date.upto(Date.today)
      @daily_attendance_labels = date_range.map { |date| date.strftime('%a, %b %d') }
    end

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
    current_time = Time.current.floor(1.hour)
    24.times do |i|
      hour = current_time - i.hours
      formatted_time = hour.strftime('%H:%M')
      start_of_hour = hour.beginning_of_hour
      end_of_hour = hour.end_of_hour

      @peak_time_data_in[formatted_time] = Attendance.where('in_time BETWEEN ? AND ?', start_of_hour, end_of_hour).count
      @peak_time_data_out[formatted_time] = Attendance.where('out_time BETWEEN ? AND ?', start_of_hour, end_of_hour).count
    end
    @peak_time_labels = @peak_time_data_in.keys.reverse # Reverse to show oldest to newest
    @peak_time_in_values = @peak_time_data_in.values.reverse
    @peak_time_out_values = @peak_time_data_out.values.reverse

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv, filename: "attendance_data_#{Date.today}.csv" }
    end
  end

  private

  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << ["Date", "Check-In Count", "Check-Out Count"]
      @daily_attendance_data.each do |date, counts|
        csv << [date, counts[:in], counts[:out]]
      end

      csv << [] # Add a blank line
      csv << ["Time (Hour)", "Peak Check-In Count", "Peak Check-Out Count"]
      @peak_time_labels.each_with_index do |time, index|
        csv << [time, @peak_time_in_values[index], @peak_time_out_values[index]]
      end
    end
  end
end
