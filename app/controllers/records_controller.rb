# frozen_string_literal: true

class RecordsController < ApplicationController
  before_action :authenticate_user!
  # Include `show` action for set_record, as it was in your previous version.
  before_action :set_record, only: %i[edit update destroy show]
  before_action :authorize_admin!, only: [:destroy]

  # Action for dynamic search of hosts (used by guest creation form)
  def search_records
    @q = Record.where(is_guest: false).ransack(params[:q]) # Only search for non-guest records as potential hosts
    @records = @q.result(distinct: true).limit(10) # Limit results for performance
    # Exclude the current record itself from being chosen as a host if editing
    if params[:exclude_id].present?
      @records = @records.where.not(id: params[:exclude_id])
    end
    render json: @records.select(:id, :name, :contact_number) # Only send necessary data
  end

  def index
    @q = Record.ransack(params[:q])
    filter_by_date(params[:created_at]) if params[:created_at].present?

    @records = Record.search_by_query(params[:query])
      .includes(:photo_attachment, :government_id_photo_attachment, :host, :guests) # Keep includes for performance if you display these
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
    @record = Record.includes(:host, :guests).find(params[:id])
    # Fetch the last attendance record for the current user for this record
    # This is used to determine if a pass can be generated.
    @last_attendance_for_current_user = @record.attendances.where(user: current_user).order(created_at: :desc).first
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
    # Prepare params before update based on checkbox state
    update_params = record_params
    if update_params[:is_guest] == "0" # Checkbox is unchecked (string "0" from form)
      update_params[:parent_record_id] = nil # Clear parent_record_id
    end

    if @record.update(update_params)
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
    params.require(:record).permit(
      :government_id_photo, :name, :photo, :contact_number, :address, :pincode,
      :city, :state, :date_of_birth, :father_name, :government_id_number,
      :user_id, :email, :is_guest, :parent_record_id, :photo_data # photo_data for webcam capture
    )
  end

  def authorize_admin!
    redirect_to records_path, alert: 'Access denied.' unless current_user.admin?
  end

  def filter_by_date(filter)
    case filter
    when 'today'
      @q.result.where(created_at: Time.zone.today.all_day)
    when 'week'
      @q.result.where(created_at: Time.zone.today.all_week)
    when 'month'
      @q.result.where(created_at: Time.zone.today.all_month)
    else
      @q.result
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