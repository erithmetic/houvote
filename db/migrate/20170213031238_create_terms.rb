class CreateTerms < ActiveRecord::Migration[5.0]
  def change
    create_table :terms do |t|
      t.text :government_slug
      t.text :person_slug
      t.text :name
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
