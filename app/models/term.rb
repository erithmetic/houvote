class Term < ApplicationRecord
  belongs_to :person, foreign_key: :person_slug, primary_key: :slug
  belongs_to :government, foreign_key: :government_slug, primary_key: :slug

  scope :current, -> { where('"terms"."start_date" < NOW() AND "terms"."end_date" > NOW()') }
end
