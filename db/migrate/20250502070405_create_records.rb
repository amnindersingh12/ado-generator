# frozen_string_literal: true

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
      t.string :government_id_number
      t.boolean :is_guest, :default => false
      t.references :records, :parent_record, foreign_key: { to_table: :records }, null: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
