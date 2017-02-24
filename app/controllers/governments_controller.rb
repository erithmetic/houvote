class GovernmentsController < ApplicationController
  before_action :set_government, only: [:show, :edit, :update, :destroy]

  # GET /governments
  def index
    @governments = Government.all
  end

  # GET /governments/1
  def show
  end

  # GET /governments/new
  def new
    @government = Government.new
  end

  # GET /governments/1/edit
  def edit
  end

  # POST /governments
  def create
    @government = Government.new(government_params)

    if @government.save
      redirect_to @government, notice: 'Government was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /governments/1
  def update
    if @government.update(government_params)
      redirect_to @government, notice: 'Government was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /governments/1
  def destroy
    @government.destroy
    redirect_to governments_url, notice: 'Government was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_government
      @government = Government.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def government_params
      params.require(:government).permit(:slug, :name, :level)
    end
end
