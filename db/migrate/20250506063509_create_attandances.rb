class CreateAttandances < ActiveRecord::Migration[8.0]
  def change
    create_table :attandances do |t|
      t.references :record, foreign_key: true
      t.datetime :in_time
      t.datetime :out_time
      t.timestamps
    end
  end
end
