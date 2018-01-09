class AddTrelloExcludedTrackerFromSyncV2ToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_excluded_trackers_v2, :text

    # set default value in MySQL, ref: https://github.com/KKBOX/redmine-trello-card-sync/issues/16
    Project.all.each do |p|
      p.trello_excluded_trackers_v2 = ''
      p.save!
    end
  end
end
