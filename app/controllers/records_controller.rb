class RecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: [:show, :edit, :update, :destroy, :history]
  before_action :authorize_admin!, only: [:destroy]

  def index
    @records = Record.all.order(created_at: :desc)
  end

  def home
    @records = Record.all.order(created_at: :desc)
    @searched_record = Record.search(params[:search])
  end




  def show
    @attendances = @record.attendances.order(created_at: :desc)
  end

  def edit
  end

  def new
    @record = Record.new
  end

  def create
    @record = current_user.records.build(record_params)
    @record.user = current_user
    if @record.save
      redirect_to records_path, notice: 'Record created successfully'
    else
      render :new
    end
  end

  def update
    if @record.update(record_params)
      redirect_to records_path, notice: 'Record updated successfully'
    else
      render :edit
    end
  end

  # Remove edit and update actions (no editing allowed)

  def destroy
    @record.destroy
    redirect_to records_path, notice: 'Record deleted successfully'
  end
  def check_in
    @attendance = @record.attendances.create(in_time: Time.current)
    redirect_to @record, notice: 'Checked in successfully'
  end

  def check_out
    @attendance = @record.attendances.last
    if @attendance && @attendance.out_time.nil?
      @attendance.update(out_time: Time.current)
      redirect_to @record, notice: 'Checked out successfully'
    else
      redirect_to @record, alert: 'No active check-in found'
    end
  end

  def history
    @attendances = @record.attendances.order(created_at: :desc)
  end

  def search
    if params[:search].present?
      @records = Record.search(params[:search])
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
    params.require(:record).permit(:name, :in_time, :out_time, :in_photo, :out_photo, :user_id, :search)
  end

  def authorize_admin!
    redirect_to records_path, alert: "Access denied." unless current_user.admin?
  end
end
