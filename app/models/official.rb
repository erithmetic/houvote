class Official < ApplicationRecord
  self.primary_key = :slug
  has_many :terms, foreign_key: :official_slug  # lol maybe not

  mount_uploader :photo, PhotoUploader
end
