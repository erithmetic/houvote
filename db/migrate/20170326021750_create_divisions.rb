class CreateDivisions < ActiveRecord::Migration[5.0]
  def change
    create_table :divisions, id: false do |t|
      t.string :slug, null: false
      t.string :government_slug
      t.string :category
      t.string :name
    end

    execute <<-SQL
      SELECT AddGeometryColumn ('public','divisions','geom',4326,'MULTIPOLYGON',2); 
    SQL

    add_column :divisions, :start_date, :datetime
    add_column :divisions, :end_date, :datetime

    add_index :divisions, :slug, unique: true
    add_index :divisions, :government_slug
    add_index :divisions, :start_date
    add_index :divisions, :end_date
  end
end
