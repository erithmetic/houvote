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
      Live.call street: street,
          city: city,
          zipcode: zipcode
    end
  end

  module Live
    def self.call(street:, city:, zipcode:)
      result = SmartyStreets::StreetAddressApi.call(
				SmartyStreets::StreetAddressRequest.new(
					input_id: "1",
					street: street,
					city: city,
					state: "TX",
					zipcode: zipcode
				)
			).first or raise "Failed getting smarty streets"
      { latitude: result.metadata.latitude, longitude: result.metadata.longitude }
    end
  end

  module Fake
    def self.call
      { latitude: 29.742722, longitude: -95.402197 }
    end
  end

end

SmartyStreets.set_auth Geocoder.auth_id, Geocoder.auth_token
