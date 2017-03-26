class GovernmentsController < ApplicationController
  before_action :set_government, only: :show

  # GET /governments/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_government
      @government = Government.find_by(slug: params[:id])
    end
end
