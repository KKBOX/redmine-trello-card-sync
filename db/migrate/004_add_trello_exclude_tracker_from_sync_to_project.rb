class AddTrelloExcludeTrackerFromSyncToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_excluded_trackers, :text, :default => nil
  end
end