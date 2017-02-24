require 'smartystreets'

module Geocoder
  extend self

  def auth_id
    ENV.fetch('SMARTYSTREETS_AUTH_ID')
  end
  def auth_token
    ENV.fetch('SMARTYSTREETS_TOKEN')
  end

  def call(street:, city:, zipcode:)
    if auth_id == 'fake'
      Fake.call
    else
      Live.call street: @address.house_number_and_street,
          city: @address.city,
          zipcode: @address.postal_code
    end
  end

  module Live
    def self.call(street:, city:, zipcode:)
      SmartyStreets.set_auth Geocoder.auth_id, Geocoder.auth_token

      result = SmartyStreets::StreetAddressApi.call(
				SmartyStreets::StreetAddressRequest.new(
					input_id: "1",
					street: street,
					city: city,
					state: "TX",
					zipcode: zipcode
				)
			).first or raise "Failed getting smarty streets"
      { latitude: result.latitude, longitude: result.longitude }
    end
  end

  module Fake
    def self.call
      { latitude: 29.742722, longitude: -95.402197 }
    end
  end

end
