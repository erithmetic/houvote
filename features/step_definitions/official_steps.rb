PLACES = {
  'houston' => {
    "type":"MultiPolygon",
    "coordinates":[[[
      [-95.9,32.3], # top left
      [-95.0,32.3], # top right
      [-95.0,29.2], # bottom right
      [-95.9,29.2] # bottom left
    ]]]
  },
  'lansing' => {
    "type":"MultiPolygon",
    "coordinates":[[[
      [-90.0,42.3], # top left
      [-90.9,42.3], # top right
      [-90.9,39.2], # bottom right
      [-90.0,39.2] # bottom left
    ]]]
  }
}

Given %r{"(.*)" is mayor of "(.*)"} do |name, place|
  official = Official.create slug: name.downcase.gsub(/\s+/, '-'), name: name

  Government.create name: place, slug: place.downcase

  division_slug = "#{place.downcase}-mayor"
  division = Division.create slug: division_slug,
    government_slug: 'houston',
    name: "City of Houston"

  Division.connection.execute <<-SQL
    UPDATE divisions
      SET geom = ST_SetSRID(
        ST_GeomFromGeoJSON('#{PLACES.fetch(place.downcase).to_json}'),
        4326
      )
    WHERE slug = '#{division_slug}'
  SQL

  term = Term.create official_slug: official.slug,
    division_slug: division.slug,
    start_date: 3.months.ago,
    end_date: 2.years.from_now
end
