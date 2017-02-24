require 'forwardable'
require 'street_address'

class Address
  extend Forwardable

  attr_accessor :addy
  def_delegators :addy, :city, :state, :postal_code

  def initialize(text)
    @addy = StreetAddress::US.parse(text)
  end


  def house_number_and_street
    [addy.number, addy.street, addy.street_type].join(' ')
  end

end
