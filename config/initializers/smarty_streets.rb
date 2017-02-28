require 'smartystreets'

unless Rails.env.test?
  SmartyStreets.set_auth Geocoder.auth_id, Geocoder.auth_token
end

