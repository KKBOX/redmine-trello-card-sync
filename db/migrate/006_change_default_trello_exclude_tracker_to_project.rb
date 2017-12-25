class ChangeDefaultTrelloExcludeTrackerToProject < ActiveRecord::Migration
  def change
    change_column :projects, :trello_excluded_trackers, :text, null: false, default: '[]'
  end
end
