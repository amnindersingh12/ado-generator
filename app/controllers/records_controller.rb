class RecordsController < ApplicationController
before_action :authenticate_user!
before_action :set_record, only: %i[edit update destroy]
before_action :authorize_admin!, only: [:destroy]

def index
  @q = Record.ransack(params[:q])
  filter_by_date(params[:created_at]) if params[:created_at].present?

  @records = @q.result(distinct: true)
                .includes(:photo_attachment, :government_id_photo_attachment,
                          attendances: %i[in_photo_attachment out_photo_attachment])
                .order(created_at: :desc)

  calculate_attendance_statistics
  @record_not_found = @records.empty? if params[:q].present?
end

def show
  @record = Record.find(params[:id])
  @has_pending_checkout = @record.attendances.any? { |a| a.out_time.nil? }
end

def new
  @record = current_user.records.build
end

def create
  @record = current_user.records.build(record_params)
  if @record.save
    redirect_to @record, notice: 'Record created successfully.'
  else
    render :new, status: :unprocessable_entity
  end
end

def update
  if @record.update(record_params)
    redirect_to records_path, notice: 'Record updated successfully'
  else
    render :edit
  end
end

def destroy
  @record.destroy
  redirect_to records_path, notice: 'Record deleted successfully.'
end

private

def set_record
  @record = Record.find(params[:id])
end

def record_params
  params.require(:record).permit(:government_id_photo, :name, :photo, :contact_number, :address, :pincode,
                                  :city, :state, :date_of_birth, :father_name, :government_id_number,
                                  :in_time, :out_time, :in_photo, :out_photo, :user_id, :email)
end

def authorize_admin!
  redirect_to records_path, alert: 'Access denied.' unless current_user.admin?
end

def filter_by_date(filter)
  case filter
  when 'today'
    @q = @q.result.where(created_at: Time.zone.today.all_day)
  when 'week'
    @q = @q.result.where(created_at: Time.zone.today.beginning_of_week..Time.zone.today.end_of_week)
  when 'month'
    @q = @q.result.where(created_at: Time.zone.today.beginning_of_month..Time.zone.today.end_of_month)
  end
end

def calculate_attendance_statistics
  @attendances = Attendance.where(record_id: @records.pluck(:id))
  @total_in = @attendances.where.not(in_time: nil).count
  @total_out = @attendances.where.not(out_time: nil).count
  @pending_records = @attendances.where(out_time: nil).count
  @total_records = @records.count
end
end
