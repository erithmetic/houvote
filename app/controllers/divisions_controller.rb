class DivisionsController < ApplicationController

  # GET /divisions/1
  def show
    @division = Division.
      select(*(Division.attribute_names + ['ST_ASGEOJSON(geom) AS geom_geojson'])).
      where(slug: params[:id]).
      first
  end

end
