# frozen_string_literal: true

class AttendancesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record
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

  def image_to_base64(image)
    return nil unless image.attached?
    file = image.download
    base64 = Base64.encode64(file).gsub(/\s+/, '')
    "data:#{image.content_type};base64,#{base64}"
  end
end