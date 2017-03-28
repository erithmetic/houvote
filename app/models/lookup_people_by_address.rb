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
      Government.joins(divisions: { terms: :official }).inject({}) do |hsh, government|
        #where('"terms"."start_date" < NOW() AND "terms"."end_date" > NOW()').
        hsh.merge(
          government => government.divisions.for_point(
            location[:latitude],
            location[:longitude]
          )
        )
      end
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
    [address.house_number_and_street, address.city, address.postal_code].compact.map do |s|
      s.downcase.strip.gsub(/\s+/, ' ')
    end.join(' ')
  end

end
