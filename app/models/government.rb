class Government < ApplicationRecord
  self.primary_key = :slug
  has_many :terms, foreign_key: :government_slug
  has_many :people, through: :terms
end
