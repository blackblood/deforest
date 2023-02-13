class CreateUsers < ActiveRecord::Migration
  def change
    create_table :deforest_users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :age
      t.string :profession

      t.timestamps null: false
    end
  end
end
