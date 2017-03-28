class Government < ApplicationRecord
  self.primary_key = :slug
  has_many :divisions, foreign_key: :government_slug
end
