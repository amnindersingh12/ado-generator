class CreateRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :records do |t|
      t.string :name
      t.datetime :in_time
      t.datetime :out_time
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
