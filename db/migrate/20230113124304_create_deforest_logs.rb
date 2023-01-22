class CreateDeforestLogs < ActiveRecord::Migration
  def change
    create_table :deforest_logs do |t|
      t.string :file_name
      t.integer :line_no
      t.string :method_name
      t.integer :count

      t.timestamps null: false
    end
  end
end
