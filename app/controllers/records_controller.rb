class RecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: [ :show, :destroy ]
  before_action :authorize_admin!, only: [:destroy]

  def authorize_admin!
    redirect_to records_path, alert: "You are not authorized to delete records." unless current_user.admin?
  end
  # Only admin can destroy
  before_action :authorize_admin!, only: [ :destroy ]

  def index
    @records = Record.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @record = Record.new
  end

  def create
    @record = current_user.records.build(record_params)
    if @record.save
      redirect_to @record, notice: "Record was successfully created."
    else
      render :new
    end
  end

  # Remove edit and update actions (no editing allowed)

  def destroy
      @record = Record.find_by(id: params[:id])
      if @record
        @record.destroy
        flash[:success] = "Record deleted"
      else
        flash[:alert] = "Record not found"
      end
      redirect_to records_path
  end

  private

  def set_record
    @record = Record.find(params[:id])
  end

  def record_params
    params.require(:record).permit(:name, :in_time, :out_time)
  end

  def authorize_admin!
    redirect_to records_path, alert: "Access denied." unless current_user.admin?
  end
end
