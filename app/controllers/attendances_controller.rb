# frozen_string_literal: true

class AttendancesController < ApplicationController
  before_action :set_record
  before_action :ensure_same_user_checking_out, only: %i[edit update]
  before_action :ensure_same_user_checking_in, only: %i[complete_check_in update_check_in]

  def new
    unless valid_state_for_check_in?(@record)
      redirect_to record_path(@record),
                  alert: 'Must complete previous attendance (check-out required) before starting a new check-in.'
      return
    end
    @attendance = @record.attendances.build(user: current_user)
  end

  def edit
    @attendance = @record.attendances.find(params[:id])
    return if @attendance.in_time && !@attendance.out_time

    redirect_to record_path(@record), alert: 'This attendance cannot be checked out.'
  end

  def create
    unless valid_state_for_check_in?(@record)
      redirect_to record_path(@record),
                  alert: 'Must complete previous attendance (check-out required) before starting a new check-in.'
      return
    end

    @attendance = @record.attendances.build(attendance_params.merge(user: current_user, in_time: Time.current))

    if @attendance.save
      redirect_to print_pass_record_attendance_path(@record, @attendance, format: :pdf)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new_check_out
    unless valid_state_for_check_out?(@record)
      redirect_to record_path(@record),
                  alert: 'Must complete previous attendance (check-in required) before starting a new check-out.'
      return
    end
    @attendance = @record.attendances.build(user: current_user)
  end

  def create_check_out
    unless valid_state_for_check_out?(@record)
      redirect_to record_path(@record),
                  alert: 'Must complete previous attendance (check-in required) before starting a new check-out.'
      return
    end

    @attendance = @record.attendances.build(attendance_params.merge(user: current_user, out_time: Time.current))

    if @attendance.save
      redirect_to print_pass_record_attendance_path(@record, @attendance, format: :pdf)
    else
      render :new_check_out, status: :unprocessable_entity
    end
  end

  def complete_check_in
    @attendance = @record.attendances.find(params[:id])
    return if !@attendance.in_time && @attendance.out_time

    redirect_to record_path(@record), alert: 'This attendance cannot be updated with a check-in.'
  end

  def update_check_in
    @attendance = @record.attendances.find(params[:id])
    if @attendance.update(attendance_params.merge(in_time: Time.current))
      redirect_to record_path(@record), notice: 'Check-in recorded.'
    else
      render :complete_check_in, status: :unprocessable_entity
    end
  end

  def update
    @attendance = @record.attendances.find(params[:id])
    if @attendance.update(attendance_params.merge(out_time: Time.current))
      redirect_to record_path(@record), notice: 'Check-out recorded.'
    else
      render :edit, status: :unprocessable_entity
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

  def ensure_same_user_checking_out
    @attendance = Attendance.find(params[:id])
    return if @attendance.user_id == current_user.id

    redirect_to record_path(@attendance.record), alert: 'You are not authorized to check out this attendance.'
  end

  def ensure_same_user_checking_in
    @attendance = Attendance.find(params[:id])
    return if @attendance.user_id == current_user.id

    redirect_to record_path(@attendance.record), alert: 'You are not authorized to check in this attendance.'
  end

  def valid_state_for_check_in?(record)
    last_attendance = record.attendances.where(user: current_user).last
    # Allow check-in if: no previous attendance, or last attendance is complete (both in_time and out_time)
    last_attendance.nil? || (last_attendance.in_time && last_attendance.out_time)
  end

  def valid_state_for_check_out?(record)
    last_attendance = record.attendances.where(user: current_user).last
    # Allow check-out if: no previous attendance, or last attendance is complete (both in_time and out_time)
    last_attendance.nil? || (last_attendance.in_time && last_attendance.out_time)
  end

  def set_record
    @record = Record.find(params[:record_id])
  end

  def attendance_params
    permitted = %i[in_photo out_photo in_time out_time]

    permitted << :purpose if @attendance.nil? || @attendance.purpose.blank?

    params.expect(attendance: [*permitted])
  end

  def image_to_base64(image)
    return nil unless image.attached?

    file = image.download
    base64 = Base64.encode64(file).gsub(/\s+/, '')
    "data:#{image.content_type};base64,#{base64}"
  end
end
