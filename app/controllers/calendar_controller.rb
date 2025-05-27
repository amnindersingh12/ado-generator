# frozen_string_literal: true

class CalendarController < ApplicationController

  before_action :authenticate_user!
  before_action :set_page_title

  def set_page_title
    @page_title = 'Attendance Calendar'
  end

  # GET /calendar
  # GET /calendar.json
  def index
    today = Time.zone.today
    @year = params[:year]&.to_i || today.year
    @month = params[:month]&.to_i || today.month
    @first_day = Date.new(@year, @month, 1)
    @last_day = @first_day.end_of_month
    @attendances_by_day = Attendance.where(in_time: @first_day..@last_day).group_by { |a| a.in_time.to_date }

    @current_month_attendances = Attendance.where(in_time: @first_day..@last_day)
    @monthly_total_in = @current_month_attendances.where.not(in_time: nil).count
    @monthly_total_out = @current_month_attendances.where.not(out_time: nil).count
    @monthly_unique_users = @current_month_attendances.select(:user_id).distinct.count
    @monthly_total_records = @current_month_attendances.select(:record_id).distinct.count
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
      format.html do
        render partial: 'calendar/day_tooltip',
               locals: { date: @date, attendances: @attendances, total_in: @total_in, total_out: @total_out,
                         pending_records: @pending_records, unique_users: @unique_users }
      end
      format.js # if you're using AJAX to render it into a div
    end
  end

  def print_day
    date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    # Use in_time and out_time instead of created_at
    @attendances = Attendance
                      .includes(:record, :user)
                      .where('(in_time BETWEEN ? AND ?) OR (out_time BETWEEN ? AND ?)',
                             date.beginning_of_day, date.end_of_day,
                             date.beginning_of_day, date.end_of_day)

    @attendances_by_record = @attendances.group_by(&:record_id)

    respond_to do |format|
      format.pdf do
        render pdf: "attendance_summary_#{date}",
               template: 'calendar/print_day',
               layout: 'pdf',
               encoding: 'UTF-8'
      end
    end
  end

  # GET /calendar/monthly_summary?year=YYYY&month=MM
  def monthly_summary
    @year = params[:year]&.to_i || Time.zone.today.year
    @month = params[:month]&.to_i || Time.zone.today.month
    @first_day = Date.new(@year, @month, 1)
    @last_day = @first_day.end_of_month

    @monthly_attendances = Attendance.where(in_time: @first_day..@last_day).includes(:user, :record)

    @monthly_summary = {
      total_check_ins: @monthly_attendances.where.not(in_time: nil).count,
      total_check_outs: @monthly_attendances.where.not(out_time: nil).count,
      unique_users: @monthly_attendances.select(:user_id).distinct.count,
      total_records: @monthly_attendances.select(:record_id).distinct.count,
      daily_breakdown: @monthly_attendances.group_by { |a| a.in_time.to_date }.map do |date, attendances|
        {
          date: date,
          check_ins: attendances.count { |a| a.in_time.present? },
          check_outs: attendances.count { |a| a.out_time.present? },
          pending: attendances.count { |a| a.out_time.nil? },
          unique_users: attendances.uniq(&:user_id).count
        }
      end,
      record_activity: calculate_record_activity(@monthly_attendances)
    }

    respond_to do |format|
      format.html # monthly_summary.html.erb
      format.pdf do
        render pdf: "monthly_attendance_summary_#{@year}_#{@month}",
               template: 'calendar/monthly_summary',
               layout: 'pdf',
               encoding: 'UTF-8'
      end
    end
  end

  private

  def calculate_record_activity(attendances)
    record_times = attendances.where.not(in_time: nil, out_time: nil).group_by(&:record)
                               .transform_values do |atts|
                                 atts.sum { |a| (a.out_time && a.in_time) ? (a.out_time - a.in_time).abs : 0 }
                               end

    most_time_record = record_times.max_by { |_record, total_time| total_time }
    least_time_record = record_times.min_by { |_record, total_time| total_time }

    frequent_records = attendances.group_by(&:record)
                                  .sort_by { |_record, count| -count.length }
                                  .take(5)

    {
      most_time: most_time_record ? { record: most_time_record[0], total_time_seconds: most_time_record[1] } : nil,
      least_time: least_time_record ? { record: least_time_record[0], total_time_seconds: least_time_record[1] } : nil,
      frequent: frequent_records.map { |record, count| { record: record, frequency: count.length } }
    }
  end
end
