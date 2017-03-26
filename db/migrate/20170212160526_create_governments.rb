class CreateGovernments < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      CREATE TABLE governments (
        slug text NOT NULL PRIMARY KEY,
        name text
      )
    SQL

    add_index :governments, :slug, unique: true
  end
end
