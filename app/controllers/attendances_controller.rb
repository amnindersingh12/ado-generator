class AttendancesController < ApplicationController
  before_action :set_record
  before_action :ensure_same_user_checking_out, only: [ :edit, :update ]


  def new
    unless all_previous_attendances_checked_out?(@record)
      redirect_to record_path(@record), alert: "Check-out required for previous entries before a new check-in."
      return
    end
    @attendance = @record.attendances.build(user: current_user)
  end

  def create
    unless all_previous_attendances_checked_out?(@record)
      redirect_to record_path(@record), alert: "Check-out required for previous entries before a new check-in."
      return
    end

    @attendance = @record.attendances.build(attendance_params.merge(user: current_user, in_time: Time.current))

    if @attendance.save!
      redirect_to @record, notice: "Checked in successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @attendance = @record.attendances.find(params[:id])
  end

  def update
    @attendance = @record.attendances.find(params[:id])
    if @attendance.update(out_time: Time.current, out_photo: params[:attendance][:out_photo])
      redirect_to @record, notice: "Check-out recorded."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def history
    @attendances = @record.attendances.order(created_at: :desc)
    @created_by = @record.user.email
  end

  private

  def ensure_same_user_checking_out
    @attendance = Attendance.find(params[:id])
    unless @attendance.user_id == current_user.id
      redirect_to record_path(@attendance.record), alert: "You are not authorized to check out this attendance."
    end
  end

  def all_previous_attendances_checked_out?(record)
    record.attendances.where(out_time: nil).none?
  end

  def set_record
    @record = Record.find(params[:record_id])
  end

  def attendance_params
    params.require(:attendance).permit(:in_photo, :out_photo, :in_time, :photo, :out_time)
  end
end
