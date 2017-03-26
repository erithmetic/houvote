class DivisionsController < ApplicationController
  before_action :set_division, only: :show

  # GET /divisions/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_division
      @division = Division.find_by(slug: params[:id])
    end
end
