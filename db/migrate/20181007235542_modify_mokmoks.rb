class ModifyMokmoks < ActiveRecord::Migration[5.2]
  def change
    change_column :mokmoks, :creator_id, :string
  end
end
