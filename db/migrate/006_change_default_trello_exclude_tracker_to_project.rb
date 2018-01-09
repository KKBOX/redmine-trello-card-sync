class ChangeDefaultTrelloExcludeTrackerToProject < ActiveRecord::Migration
  def change
    change_column :projects, :trello_excluded_trackers, :text

    # set default value in MySQL, ref: https://github.com/KKBOX/redmine-trello-card-sync/issues/16
    Project.all.each do |p|
      p.trello_excluded_trackers = "[]"
      p.save!
    end
  end
end
