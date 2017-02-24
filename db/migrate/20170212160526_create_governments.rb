class CreateGovernments < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      CREATE TABLE governments (
        slug text NOT NULL PRIMARY KEY,
        name text,
        level text,
        category text
      )
    SQL

    execute <<-SQL
      SELECT AddGeometryColumn ('public','governments','geom',4326,'MULTIPOLYGON',2);
    SQL
  end
end
