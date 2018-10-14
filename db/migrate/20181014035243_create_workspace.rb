class CreateWorkspace < ActiveRecord::Migration[5.2]
  def change
    create_table :workspaces do |t|
      t.string :access_token
      t.string :scope
      t.string :team_name
      t.string :team_id
      t.string :bot_user_id
      t.string :bot_access_token
      t.timestamps null: false
    end
  end
end