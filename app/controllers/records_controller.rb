class RecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: [ :edit, :update, :destroy ]
  before_action :authorize_admin!, only: [ :new, :destroy ]

  def index
    @q = Record.ransack(params[:q])

    # Apply date filtering
    filter_by_date(params[:created_at]) if params[:created_at].present?

    # Final filtered result
    @records = @q.result(distinct: true).includes(:photo_attachment, :government_id_photo_attachment, attendances: [:in_photo_attachment, :out_photo_attachment]).order(created_at: :desc)

    # Compute stats based on those records
    calculate_attendance_statistics
  end


  def show
    @record = Record.find(params[:id])

    @has_pending_checkout =  @record.attendances.count { |a| a.out_time.nil? } > 0
  end

  def new
    @record = current_user.records.build
  end

  def create
    @record = current_user.records.build(record_params)
    if @record.save
      redirect_to @record, notice: "Record created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def search
    @records = Record.where("name ILIKE ?", "%#{params[:query]}%")
    render :index
  end

  def update
    if @record.update(record_params)
      redirect_to records_path, notice: "Record updated successfully"
    else
      render :edit
    end
  end

# Remove edit and update actions (no editing allowed)

def destroy
  @record = Record.find(params[:id])
  @record.destroy
  redirect_to records_path, notice: "Record deleted successfully."
end

  def search
    if params[:search].present?
      @records = Record.find_by(name: params[:search])
      if @records.empty?
        @record_not_found = true
      end
    else
      @records = Record.none
    end

    render :index
  end

  private

  def set_record
    @record = Record.find(params[:id])
  end

  def record_params
    params.require(:record).permit(:government_id_photo, :name, :id, :photo, :contact_number, :address, :pincode, :city, :state, :date_of_birth, :father_name, :government_id_number, :created_at, :updated_at, :in_time, :out_time, :in_photo, :out_photo, :user_id, :search)
  end

  def authorize_admin!
    redirect_to records_path, alert: "Access denied." unless current_user.admin?
  end

  def filter_by_date(filter)
    case filter
    when "today"
      @q = @q.where(created_at: Date.today.all_day)
    when "week"
      start_of_week = Date.today.beginning_of_week(:sunday)
      end_of_week = Date.today.end_of_week(:sunday)
      @q = @q.where(created_at: start_of_week..end_of_week)
    when "month"
      start_of_month = Date.today.beginning_of_month
      end_of_month = Date.today.end_of_month
      @q = @q.where(created_at: start_of_month..end_of_month)
    when "all"
      # No filtering for all time
    else
      # Default: No date filtering applied
    end
  end

  def calculate_attendance_statistics
    @attendances = Attendance.where(record_id: @records.pluck(:id))  # Assuming there's a record_id association
    @total_in = @attendances.where.not(in_time: nil).count
    @total_out = @attendances.where.not(out_time: nil).count
    @pending_records = @attendances.where(out_time: nil).count
    @total_records = @records.count
  end
end
