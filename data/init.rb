require 'yaml'

def init_yml(path, division_id)
  yml = YAML::load_file path
  yml ||= {}
  yml['vip_division_id'] = division_id
  File.open(path, 'w') { |out| out.puts YAML::dump yml }
end


# TX House districts

Dir[File.expand_path('../meta/divisions/tx-house-district-*.yml', __FILE__)].each do |f|
  num = File.basename(f, '.yml').split('-').last
  init_yml f, "ocd-division/country:us/state:tx/sldl:#{num}"
end


# TX US House districts

Dir[File.expand_path('../meta/divisions/us-house-115-tx-district-*.yml', __FILE__)].each do |f|
  num = File.basename(f, '.yml').split('-').last
  init_yml f, "ocd-division/country:us/state:tx/cd:#{num}"
end


# Harris County Commissioners' Court

Dir[File.expand_path('../meta/divisions/harris-county-commissioners-court-*.yml', __FILE__)].each do |f|
  num = File.basename(f, '.yml').split('-').last
  init_yml f, "ocd-division/country:us/state:tx/county:harris/council_district:#{num}"
end


# Houston City Council

Dir[File.expand_path('../meta/divisions/hou-city-council-*.yml', __FILE__)].each do |f|
  next if /large/.match(f)
  num = File.basename(f, '.yml').split('-').last
  init_yml f, "ocd-division/country:us/state:tx/place:houston/council_district:#{num}"
end
