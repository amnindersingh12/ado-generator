class CreateRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :records do |t|
      t.string :name
      t.string :email
      t.string :contact_number
      t.string :address
      t.integer :pincode
      t.string :city
      t.string :state
      t.datetime :date_of_birth
      t.string :father_name
      t.integer :government_id_number
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
