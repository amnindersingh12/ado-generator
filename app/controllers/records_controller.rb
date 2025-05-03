class RecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_record, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_admin!, only: [ :destroy ]

  def index
  @records = Record.all.order(created_at: :desc)
  end
def home
  @records = Record.all.order(created_at: :desc)

end

  def show 
  end
  def edit  
  end

  def new
    @record = Record.new
  end

  def create
    @record = current_user.records.build(record_params)
    @record.in_time = Time.now
    respond_to do |format|
      if @record.save
        format.html { redirect_to @record, notice: "Record was successfully created with check-in details." }
        format.json { render :show, status: :created, location: @record }
      else
        format.html { render :new }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end
  def update
    # Only update out_time and out_photo
    update_params = { out_time: Time.current }
    # Add out_photo to update_params if it's provided
    update_params[:out_photo] = params[:record][:out_photo] if params[:record] && params[:record][:out_photo]

    respond_to do |format|
      if @record.update(update_params)
        format.html { redirect_to @record, notice: "Record was successfully updated with check-out details." }
        format.json { render :show, status: :ok, location: @record }
      else
        format.html { render :edit }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  # Remove edit and update actions (no editing allowed)

  def destroy
    @record.destroy
    respond_to do |format|
      format.html { redirect_to records_url, notice: "Record was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_record
    @record = Record.find(params[:id])
  end

  def record_params
    params.require(:record).permit(:name, :in_time, :out_time, :in_photo, :out_photo, :user_id)
  end

  def authorize_admin!
    redirect_to records_path, alert: "Access denied." unless current_user.admin?
  end
end
