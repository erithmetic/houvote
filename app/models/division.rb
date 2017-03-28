class Division < ApplicationRecord
  self.primary_key = :slug
  has_many :terms, foreign_key: :division_slug

  scope :voting_precincts_with_centroids, -> () {
    select(*(Division.attribute_names + ['ST_ASGEOJSON(ST_CENTROID(geom)) AS centroid'])).
    where(
      government_slug: 'tx-county',
      category: 'Voting Precint'
    )
  }

  scope :for_point, -> (lat, lon) {
    where(
      "ST_Contains(divisions.geom, ST_Transform(ST_SetSRID(ST_MakePoint(?,?), 4326), 4326))",
      lon,
      lat
    )
  }

  def centroid
    @centroid ||= JSON.parse(attribute(:centroid))
  end

  def centroid_lat
    centroid['coordinates'].last
  end

  def centroid_lon
    centroid['coordinates'].first
  end
end
