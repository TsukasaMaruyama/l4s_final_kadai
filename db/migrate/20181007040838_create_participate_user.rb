class CreateParticipateUser < ActiveRecord::Migration[5.2]
  def change
    create_table :participate_users do |t|
      t.string :mokmok_id
      t.string :user_id
      t.text :comment
      t.timestamps null: false
    end
  end
end
