class OfficialsController < ApplicationController
  before_action :set_official, only: :show

  # GET /officials/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_official
      @official = Official.find_by(slug: params[:id])
    end

end
