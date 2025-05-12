class CreateAttendance < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :record, null: false, foreign_key: true
      t.datetime :in_time
      t.datetime :out_time
      t.timestamps
    end
  end
end
