class LookupPeopleByAddress

  def self.call(address_text)
    new(address_text).call
  end

  attr_accessor :address_text

  def initialize(address_text)
    @address_text = address_text
  end

  def call
    if address && location
      Person.
        joins(terms: :government).
        where("ST_Contains(governments.geom, ST_Transform(ST_SetSRID(ST_MakePoint(?,?), 4326), 4326))",
              location[:longitude], location[:latitude]).
        where('"terms"."start_date" < NOW() AND "terms"."end_date" > NOW()').
        to_a.
        group_by { |p| p.terms.first.government }
    else
      []
    end
  end

  def address
    @address ||= Address.new address_text
  end

  def location
    @location ||= Rails.cache.fetch(location_cache_key) {
      Geocoder.call(
        street: address.house_number_and_street,
        city: address.city,
        zipcode: address.postal_code
      )
    }
  end

  def location_cache_key
    [address.house_number_and_street, address.city, address.postal_code].map do |s|
      s.downcase.strip.gsub(/\s+/, ' ')
    end.join(' ')
  end

end
