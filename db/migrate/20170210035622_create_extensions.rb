class CreateExtensions < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
CREATE EXTENSION postgis;
    SQL
  end
end
