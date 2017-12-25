class ChangeTrelloExcludeTrackerDefaultToProject < ActiveRecord::Migration
  def change
    change_column :projects, :trello_excluded_trackers, :text, default: '[]'
  end
end
