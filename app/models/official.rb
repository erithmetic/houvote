class Official < ApplicationRecord
  self.primary_key = :slug
  has_many :terms, foreign_key: :official_slug  # lol maybe not
  has_many :governemnts, through: :terms

  mount_uploader :photo, PhotoUploader
end
