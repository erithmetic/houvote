class CreateOfficials < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      CREATE TABLE officials (
        slug text NOT NULL PRIMARY KEY,
        name text,
        born date,
        photo text,
        third_party_photo_url text,
        url text,
        addresses json,
        party text,
        phones json,
        urls json,
        emails json,
        channels json
      )
    SQL

    add_index :officials, :slug, unique: true
  end
end
