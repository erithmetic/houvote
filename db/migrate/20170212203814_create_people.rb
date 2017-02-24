class CreatePeople < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      CREATE TABLE people (
        slug text NOT NULL PRIMARY KEY,
        name text,
        born date,
        photo text,
        third_party_photo_url text,
        url text
      )
    SQL
  end
end
