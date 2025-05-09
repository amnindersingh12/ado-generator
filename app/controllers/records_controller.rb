class RecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: [ :edit, :update, :destroy ]
  before_action :authorize_admin!, only: [ :new, :destroy ]

  def index
    @q = Record.ransack(params[:q])
    @records = @q.result.includes(:user)
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
    params.require(:record).permit(:name, :id, :photo, :contact_number, :address, :pincode, :city, :state, :date_of_birth, :father_name, :government_id_number, :created_at, :updated_at, :in_time, :out_time, :in_photo, :out_photo, :user_id, :search)
  end

  def authorize_admin!
    redirect_to records_path, alert: "Access denied." unless current_user.admin?
  end
end
