class CreateTerms < ActiveRecord::Migration[5.0]
  def change
    create_table :terms do |t|
      t.text :division_slug
      t.text :official_slug
      t.text :name
      t.date :start_date
      t.date :end_date
    end

    add_index :terms, [:division_slug, :official_slug]
    add_index :terms, :start_date
    add_index :terms, :end_date
  end
end
