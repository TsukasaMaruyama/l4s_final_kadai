class AddColumnToMokmoks < ActiveRecord::Migration[5.2]
  def change
    add_column :mokmoks, :channel_id, :string
    add_column :mokmoks, :team_id, :string
  end
end
