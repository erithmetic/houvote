class Person < ApplicationRecord
  self.primary_key = :slug
  has_many :terms, foreign_key: :person_slug  # lol maybe not
  has_many :governemnts, through: :terms
end
