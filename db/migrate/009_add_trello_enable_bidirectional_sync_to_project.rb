class AddTrelloEnableBidirectionalSyncToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_enable_bidirectional_sync, :boolean, default: false
  end
end
