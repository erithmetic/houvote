ENV['CACHE_STORE'] = 'file_store'

require_relative '../config/environment'
Division.connection

require 'httparty'
require 'pry'
require 'uri'

GOOGLE_ADDRESS_PARTS = %w{street_number route locality administrative_area_level_1 postal_code}

def reverse_geocode(lat, lon)

  Rails.cache.fetch "address-#{lat}-#{lon}" do
    response = HTTParty.get "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lon}&key=#{ENV.fetch('GOOGLE_GEOCODING_API_KEY')}"
    json = JSON.parse(response.body)

    unless result = json['results'].first
      puts "Unable to find an address for #{lat},#{lon}: #{json.inspect}"
      return nil
    end

    result['address_components'].
      select { |a| a['types'].any? { |t| GOOGLE_ADDRESS_PARTS.include?(t) } }.
      map { |a| a['long_name'] }.
      join(' ')
  end
end

def fetch_vip(address)

  Rails.cache.fetch "vip-#{address}" do
    response = HTTParty.get "https://www.googleapis.com/civicinfo/v2/representatives?address=#{URI.encode(address)}&key=#{ENV.fetch('GOOGLE_CIVIC_API_KEY')}"

    JSON.parse response.body
  end
end

offices = {}
officials = {}

# Find the centroid of each voting precinct, reverse-geocode, then look up
# candidates for each
#
Division.voting_precincts_with_centroids.each do |precinct|
  puts precinct.name

  if address = reverse_geocode(precinct.centroid_lat, precinct.centroid_lon)
    puts "Address: #{address}"
  else
    puts "No address found"
    next
  end

  civics = fetch_vip address

  slug_indices = []

  unless civics['officials']
    puts "No officials for address #{address}: #{civics}"
    next
  end

  # Store all the officials using unique slugs
  civics['officials'].each do |official|
    slug = official['name'].downcase.gsub(/[^\w]+/, '-')

    if officials[slug].nil?
      official['slug'] = slug
      officials[slug] = official
      slug_indices << slug
    elsif officials[slug] != official.merge('slug' => slug)
      free_slug_num = (1..99).find { |n| officials["#{slug}-#{n}"].nil? }
      new_slug = "#{slug}-#{free_slug_num}"
      official['slug'] = new_slug
      officials[new_slug] = official
      slug_indices << new_slug
    else
      slug_indices << slug
    end
  end

  civics['offices'].each do |office|
    slug = office['name'].downcase.gsub /[^\w]+/, '-'

    offices[slug] ||= {
      name: office['name'],
      vip_division_id: office['divisionId'],
    }
    offices[slug][:official_slugs] = office['officialIndices'].
      map { |i| slug_indices[i] }
  end
end

officials.each do |slug, data|
  path = File.expand_path("../meta/officials/#{slug}.yml", __FILE__)
  puts "Writing #{path}"
  File.open(path, 'w') { |f| f.puts YAML::dump(data) }
end

offices.each do |slug, office|
  division_file = Dir[File.expand_path("../meta/divisions/*.yml", __FILE__)].find do |f|
    if div = YAML::load_file(f)
      div['vip_division_id'] == office[:vip_division_id]
    end
  end

  if division_file
    division_slug = File.basename(division_file, '.yml')
    term_file_path = File.expand_path("../meta/terms/#{slug}.yml", __FILE__)
    puts "Writing #{term_file_path}"
    File.open(term_file_path, 'w') do |f|
      f.puts YAML::dump(office.merge(division_slug: division_slug))
    end
  else
    puts "No division file match for office #{slug} via #{office[:vip_division_id]}"
  end
end
