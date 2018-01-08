class AddTrelloExcludedTrackerFromSyncV2ToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_excluded_trackers_v2, :text, null: false, default: ""
  end
end
