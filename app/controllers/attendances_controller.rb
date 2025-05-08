class AttendancesController < ApplicationController
  before_action :set_record

  def new
    @attendance = @record.attendances.build(user: current_user)
  end
  def index
  @record_history = @record.attendance.order(created_at: :desc)
  end

  def create
    @attendance = @record.attendances.build(attendance_params.merge(user: current_user, in_time: Time.current))
    if @attendance.save
      redirect_to @record, notice: "Check-in recorded."
    else
      render :new, status: :unprocessable_entity
    end
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

  def set_record
    @record = Record.find(params[:record_id])
  end

  def attendance_params
    params.require(:attendance).permit(:in_photo, :out_photo, :in_time, :out_time)
  end
end
