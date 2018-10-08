class CreateMokmoks < ActiveRecord::Migration[5.2]
  def change
    create_table :mokmoks do |t|
      t.integer :creator_id
      t.string :title
      t.text :description
      t.string :place
      t.datetime :start_date 
      t.datetime :finish_date
      t.timestamps null: false
    end
  end
end
