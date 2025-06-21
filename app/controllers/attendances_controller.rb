# frozen_string_literal: true

class AttendancesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: %i[new_visit create_or_update_visit history print_pass]
  before_action :ensure_same_user_permission, only: %i[create_or_update_visit]

  # GET /records/:record_id/attendances/new_visit
  # This acts as the flexible entry point for attendance.
  # It finds a *truly pending* attendance or initializes a new one.
  def new_visit
    # Find the most recent attendance for this record by the current user
    # that is explicitly INCOMPLETE:
    # (has an in_time AND a NULL out_time) OR (has an out_time AND a NULL in_time).
    # This query will ignore fully completed records AND records where both times are NULL (effectively "blank" records).
    @attendance = @record.attendances
                         .where(user: current_user)
                         .where("
                           (in_time IS NOT NULL AND out_time IS NULL) OR
                           (in_time IS NULL AND out_time IS NOT NULL)
                         ")
                         .order(created_at: :desc)
                         .first

    if @attendance.nil?
      # This block executes if:
      # 1. There are NO pending (partially filled) attendance records.
      # 2. All previous attendance records are fully completed.
      # 3. Any "blank" attendance records (both times NULL) are ignored, leading to a new record.
      @attendance = @record.attendances.build(user: current_user)
      @form_action = :create_new_attendance # Flag for view to show "Start New Attendance"
    else
      # Found an existing, partially filled attendance record.
      # The user is then directed to complete that specific record.
      @form_action = :complete_existing_attendance # Flag for view to show "Complete Attendance"
    end

    render 'attendances/flexible_form'
  end

  # POST/PATCH /records/:record_id/attendances/create_or_update_visit
  def create_or_update_visit
    if params[:id].present?
      @attendance = @record.attendances.find(params[:id])
      unless @attendance.user == current_user
        redirect_to record_path(@record), alert: "You are not authorized to modify this attendance."
        return
      end
      new_purpose = @attendance.purpose.present? ? @attendance.purpose : attendance_params[:purpose]
    else
      @attendance = @record.attendances.build(user: current_user)
      new_purpose = attendance_params[:purpose]
    end

    in_time_to_set = attendance_params[:set_in_time] == '1' ? Time.current : @attendance.in_time
    out_time_to_set = attendance_params[:set_out_time] == '1' ? Time.current : @attendance.out_time

    # Validate that at least one time or purpose is being set for a new record
    if @attendance.new_record? && in_time_to_set.blank? && out_time_to_set.blank? && new_purpose.blank?
      @attendance.errors.add(:base, "An attendance record must have a purpose and at least one time set.")
      @form_action = :create_new_attendance
      render 'attendances/flexible_form', status: :unprocessable_entity
      return
    end

    if @attendance.update(purpose: new_purpose, in_time: in_time_to_set, out_time: out_time_to_set)
      if @attendance.in_time.present? && @attendance.out_time.present?
        redirect_to print_pass_record_attendance_path(@record, @attendance, format: :pdf),
                    notice: "#{@record.name}'s attendance completed successfully!"
      else
        redirect_to record_path(@record),
                    notice: "#{@record.name}'s attendance updated (still pending completion)."
      end
    else
      @form_action = params[:id].present? ? :complete_existing_attendance : :create_new_attendance
      render 'attendances/flexible_form', status: :unprocessable_entity
    end
  end

  # GET /records/:record_id/attendances/history
  def history
    @created_by = @record.user.email
    @attendances = @record.attendances.order(in_time: :desc)

    if params[:from].present? && params[:to].present?
      from = Date.parse(params[:from]).beginning_of_day
      to = Date.parse(params[:to]).end_of_day
      @attendances = @attendances.where(in_time: from..to)
    end

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "attendance_#{@record.id}",
               template: 'attendances/record_report',
               layout: 'pdf',
               margin: { top: 10, bottom: 10, left: 10, right: 10 }
      end
    end
  end

  # GET /records/:record_id/attendances/:id/print_pass
  def print_pass
    @attendance = @record.attendances.find(params[:id])
    @token = @attendance.id
    respond_to do |format|
      format.pdf do
        render pdf: "attendance_pass_#{@attendance.id}",
               template: 'attendances/pass',
               layout: 'pdf',
               margin: { top: 5, bottom: 5, left: 10, right: 10 }
      end
    end
  end

  # GET /attendances/monthly_summary
  def monthly_summary
    @month = params[:month]&.to_i || Time.current.month
    @year = params[:year]&.to_i || Time.current.year

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    # Fetch all relevant attendances for the month.
    # This includes attendances:
    # 1. Whose in_time falls within the month
    # 2. Whose out_time falls within the month
    # 3. That started before the month and ended after the month (spanning across)
    # 4. That started before or within the month and are still pending (out_time is nil)
    @all_monthly_attendances = Attendance.includes(:record, :user)
                                     .where("(in_time >= ? AND in_time <= ?) OR (out_time >= ? AND out_time <= ?) OR (in_time < ? AND out_time > ?) OR (in_time <= ? AND out_time IS NULL)",
                                            start_date.beginning_of_day, end_date.end_of_day,
                                            start_date.beginning_of_day, end_date.end_of_day,
                                            start_date.beginning_of_day, end_date.end_of_day,
                                            end_date.end_of_day # Check-ins up to end of month that are pending
                                           )
                                     .order(:in_time)


    @monthly_summary = {
      total_check_ins: @all_monthly_attendances.where.not(in_time: nil).count,
      total_check_outs: @all_monthly_attendances.where.not(out_time: nil).count,
      unique_users: @all_monthly_attendances.where.not(user_id: nil).distinct.count(:user_id),
      total_records: @all_monthly_attendances.where.not(record_id: nil).distinct.count(:record_id),
      daily_breakdown: [],
      record_activity: {
        most_time: nil,
        least_time: nil,
        top_time_spent: [],
        frequent: []
      },
      user_activity: {},
      purpose_breakdown: {},
      pending_checkouts: []
    }

    # --- Daily Breakdown ---
    (start_date..end_date).each do |date|
      # Filter for attendances active on this specific day
      attendances_active_on_day = @all_monthly_attendances.select do |a|
        (a.in_time && a.in_time.to_date == date) || # Checked in today
        (a.out_time && a.out_time.to_date == date) || # Checked out today
        (a.in_time && a.out_time && a.in_time.to_date < date && a.out_time.to_date > date) || # Spanned over today
        (a.in_time && a.out_time.nil? && a.in_time.to_date <= date) # Checked in on or before today and still pending
      end

      check_ins = attendances_active_on_day.count { |a| a.in_time&.to_date == date }
      check_outs = attendances_active_on_day.count { |a| a.out_time&.to_date == date }
      # Pending: Records checked in on or before `date` and still pending on `date`
      pending = @all_monthly_attendances.count do |a|
        a.in_time && a.in_time.to_date <= date && (a.out_time.nil? || a.out_time.to_date > date)
      end

      unique_records_daily = attendances_active_on_day.map(&:record_id).compact.uniq.count
      unique_users_daily = attendances_active_on_day.map(&:user_id).compact.uniq.count

      @monthly_summary[:daily_breakdown] << {
        date: date,
        check_ins: check_ins,
        check_outs: check_outs,
        pending: pending,
        unique_records: unique_records_daily,
        unique_users: unique_users_daily
      }
    end


    # --- Record Activity ---
    # Only consider attendances that have both in_time and out_time within the month for time calculations
    records_with_full_visits = @all_monthly_attendances.where.not(in_time: nil, out_time: nil)
                                                      .select { |a| a.in_time >= start_date.beginning_of_day && a.out_time <= end_date.end_of_day }


    # Calculate total time spent per record
    total_time_per_record = records_with_full_visits.group_by(&:record_id).transform_values do |attendances_for_record|
      total_seconds = attendances_for_record.sum { |a| (a.out_time - a.in_time).to_i }
      last_attendance = attendances_for_record.max_by(&:in_time) # Get the latest attendance for last interaction display
      { total_time_seconds: total_seconds, last_attendance: last_attendance }
    end

    if total_time_per_record.any?
      # Most time spent
      most_time_data = total_time_per_record.max_by { |_record_id, data| data[:total_time_seconds] }
      if most_time_data
        record = Record.find_by(id: most_time_data.first)
        @monthly_summary[:record_activity][:most_time] = {
          record: record,
          total_time_seconds: most_time_data.last[:total_time_seconds],
          last_attendance: most_time_data.last[:last_attendance]
        }
      end

      # Least time spent
      least_time_data = total_time_per_record.min_by { |_record_id, data| data[:total_time_seconds] }
      if least_time_data
        record = Record.find_by(id: least_time_data.first)
        @monthly_summary[:record_activity][:least_time] = {
          record: record,
          total_time_seconds: least_time_data.last[:total_time_seconds],
          last_attendance: least_time_data.last[:last_attendance]
        }
      end

      # Top records by time spent (e.g., top 5)
      @monthly_summary[:record_activity][:top_time_spent] = total_time_per_record
        .sort_by { |_record_id, data| -data[:total_time_seconds] } # Sort descending
        .first(5) # Take top 5
        .map do |record_id, data|
          { record: Record.find_by(id: record_id), total_time_seconds: data[:total_time_seconds] }
        end
    end

    # Most Frequent Records
    record_frequency = @all_monthly_attendances.group(:record_id).count
    @monthly_summary[:record_activity][:frequent] = record_frequency
      .sort_by { |_record_id, count| -count } # Sort descending
      .first(5) # Top 5 frequent records
      .map { |record_id, frequency| { record: Record.find_by(id: record_id), frequency: frequency } }


    # --- User Activity Summary ---
    user_data = {}
    @all_monthly_attendances.each do |attendance|
      user_id = attendance.user_id
      next unless user_id # Skip if no user_id (e.g., if attendance can be unassigned)

      user_data[user_id] ||= { user: attendance.user, check_ins: 0, check_outs: 0, records_managed: Set.new }
      user_data[user_id][:check_ins] += 1 if attendance.in_time.present? && attendance.in_time.to_date >= start_date && attendance.in_time.to_date <= end_date
      user_data[user_id][:check_outs] += 1 if attendance.out_time.present? && attendance.out_time.to_date >= start_date && attendance.out_time.to_date <= end_date
      user_data[user_id][:records_managed] << attendance.record_id if attendance.record_id.present?
    end
    @monthly_summary[:user_activity] = user_data.transform_values { |data| data.merge(records_managed: data[:records_managed].size) }


    # --- Purpose Breakdown ---
    @monthly_summary[:purpose_breakdown] = @all_monthly_attendances.group(:purpose).count.sort_by { |_purpose, count| -count }.first(5).to_h # Top 5 purposes


    # --- Currently Checked-In Records (Pending Check-Out) ---
    # This specifically looks for records that are currently open (out_time is nil)
    # and whose in_time is within or before the selected month.
    @monthly_summary[:pending_checkouts] = @all_monthly_attendances
      .select { |a| a.out_time.nil? && a.in_time.present? && a.in_time <= end_date.end_of_day }
      .sort_by(&:in_time)

    respond_to do |format|
      format.html # Renders monthly_summary.html.erb
      format.pdf do
        render pdf: "monthly_attendance_summary_#{@month}_#{@year}",
               template: 'attendances/monthly_summary', # Use the view we created
               layout: 'pdf',
               margin: { top: 10, bottom: 10, left: 10, right: 10 },
               header: { html: { template: 'layouts/pdf_header' } }, # Optional header
               footer: { html: { template: 'layouts/pdf_footer' } }  # Optional footer
      end
    end
  end


  private

  def ensure_same_user_permission
    if params[:id].present?
      @attendance = Attendance.find(params[:id])
      unless @attendance.user == current_user
        redirect_to record_path(@record), alert: 'You are not authorized to modify this attendance.'
        return
      end
    end
  end

  def set_record
    @record = Record.find(params[:record_id])
  end

  def attendance_params
    params.require(:attendance).permit(:purpose, :set_in_time, :set_out_time)
  end

  # Helper method for converting time seconds to readable format
  # This typically goes into app/helpers/application_helper.rb or app/helpers/attendance_helper.rb
  # For direct inclusion in controller for self-containment (less ideal for large apps, but works)
  helper_method :time_spent_cal # Makes it available in the view

  def time_spent_cal(seconds)
    return '0h 0m' if seconds.nil? || seconds.zero?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours}h #{minutes}m"
  end
end