class RecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: %i[edit update destroy]
  before_action :authorize_admin!, only: [:destroy]

  def search
    @q = Record.ransack(params[:q])
    @records = @q.result(distinct: true)
  end

  def check_in
    @record = Record.find(params[:id])
    @attendance = @record.attendances.new # Prepare a new attendance record
  end

  def complete_check_in
    @record = Record.find(params[:record_id]) # Assuming record_id is passed
    @attendance = @record.attendances.new(in_time: Time.current)
    if @attendance.save
      redirect_to @record, notice: "#{@record.name} checked in."
    else
      render :check_in, alert: 'Check-in failed.'
    end
  end

  def new_check_out
    @record = Record.find(params[:id])
    @attendance = @record.attendances.order(created_at: :desc).first # Find the latest attendance
    if @attendance&.in_time.present? && @attendance.out_time.nil?
      # Proceed with check-out form
    else
      redirect_to @record, alert: "No active check-in found for #{@record.name}."
    end
  end

  def create_check_out
    @record = Record.find(params[:record_id]) # Assuming record_id is passed
    @attendance = @record.attendances.order(created_at: :desc).first
    if @attendance&.in_time.present? && @attendance.out_time.nil?
      @attendance.update(out_time: Time.current)
      redirect_to @record, notice: "#{@record.name} checked out."
    else
      redirect_to @record, alert: "No active check-in found for #{@record.name}."
    end
  end

  def index
    @q = Record.ransack(params[:q])
    filter_by_date(params[:created_at]) if params[:created_at].present?

    @records = @q.result(distinct: true)
                 .includes(:photo_attachment, :government_id_photo_attachment,
                           attendances: %i[])
                 .order(created_at: :desc)

    calculate_attendance_statistics
    @record_not_found = @records.empty? if params[:q].present?
    @records = case params[:filter]
               when 'checked_in'
                 @q.result.joins(:attendances).where.not(attendances: { in_time: nil, out_time: nil }).distinct.order(created_at: :desc)
               when 'checked_out'
                 @q.result.joins(:attendances).where.not(attendances: { out_time: nil }).where.not(attendances: { in_time: nil }).distinct.order(created_at: :desc)
               when 'pending'
                 @q.result.joins(:attendances).where(attendances: { out_time: nil }).where.not(attendances: { in_time: nil }).distinct.order(created_at: :desc)
               when 'all'
                 @q.result.order(created_at: :desc)
               else
                 @q.result.order(created_at: :desc)
               end

    @total_records = Record.count
    @total_in = Attendance.where.not(in_time: nil).where.not(out_time: nil).count
    @total_out = Attendance.where.not(out_time: nil).where.not(in_time: nil).count
    @pending_records = Attendance.where(out_time: nil).where.not(in_time: nil).count
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
                                   :in_time, :out_time, :user_id, :email)
  end

  def authorize_admin!
    redirect_to records_path, alert: 'Access denied.' unless current_user.admin?
  end

  def filter_by_date(filter)
    case filter
    when 'today'
      @q = @q.result.where(created_at: Time.zone.today.all_day)
    when 'week'
      @q = @q.result.where(created_at: Time.zone.today.all_week)
    when 'month'
      @q = @q.result.where(created_at: Time.zone.today.all_month)
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
