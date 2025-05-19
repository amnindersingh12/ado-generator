class AttendancesController < ApplicationController
  before_action :set_record
  before_action :ensure_same_user_checking_out, only: [ :edit, :update ]
  before_action :ensure_same_user_checking_in, only: [ :complete_check_in, :update_check_in ]



  def new
    unless valid_state_for_check_in?(@record)
      redirect_to record_path(@record), alert: "Must complete previous attendance (check-out required) before starting a new check-in."
      return
    end
    @attendance = @record.attendances.build(user: current_user)
  end

  def create
    unless valid_state_for_check_in?(@record)
      redirect_to record_path(@record), alert: "Must complete previous attendance (check-out required) before starting a new check-in."
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
      redirect_to record_path(@record), alert: "Must complete previous attendance (check-in required) before starting a new check-out."
      return
    end
    @attendance = @record.attendances.build(user: current_user)
  end

  def create_check_out
    unless valid_state_for_check_out?(@record)
      redirect_to record_path(@record), alert: "Must complete previous attendance (check-in required) before starting a new check-out."
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
    unless !@attendance.in_time && @attendance.out_time
      redirect_to record_path(@record), alert: "This attendance cannot be updated with a check-in."
    end
  end

  def update_check_in
    @attendance = @record.attendances.find(params[:id])
    if @attendance.update(attendance_params.merge(in_time: Time.current))
      redirect_to @record, notice: "Check-in completed successfully."
    else
      render :complete_check_in, status: :unprocessable_entity
    end
  end

  def edit
    @attendance = @record.attendances.find(params[:id])
    unless @attendance.in_time && !@attendance.out_time
      redirect_to record_path(@record), alert: "This attendance cannot be checked out."
    end
  end

  def update
    @attendance = @record.attendances.find(params[:id])
    if @attendance.update(attendance_params.merge(out_time: Time.current))
      redirect_to @record, notice: "Check-out recorded."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def history
    @attendances = @record.attendances.order(created_at: :desc)
    @created_by = @record.user.email
  end

def print_pass
  @attendance = @record.attendances.find(params[:id])
  @token = generate_token(@attendance)

  respond_to do |format|
    format.pdf do
      render pdf: "attendance_pass_#{@attendance.id}",
             template: "attendances/pass",
             layout: "pdf"
    end
  end
end

private

def generate_token(attendance)
  record_id = attendance.record_id
  timestamp = attendance.created_at.strftime("%Y%m%d%H%M%S")
  random_suffix = SecureRandom.hex(2)
  "REC#{record_id}-#{timestamp}-#{random_suffix}"
end

  def ensure_same_user_checking_out
    @attendance = Attendance.find(params[:id])
    unless @attendance.user_id == current_user.id
      redirect_to record_path(@attendance.record), alert: "You are not authorized to check out this attendance."
    end
  end

  def ensure_same_user_checking_in
    @attendance = Attendance.find(params[:id])
    unless @attendance.user_id == current_user.id
      redirect_to record_path(@attendance.record), alert: "You are not authorized to check in this attendance."
    end
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
    params.require(:attendance).permit(:in_photo, :out_photo, :in_time, :out_time, :attendance)
  end

  def image_to_base64(image)
  return nil unless image.attached?

  file = image.download
  base64 = Base64.encode64(file).gsub(/\s+/, "")
  "data:#{image.content_type};base64,#{base64}"
end


end
