class AddTrelloListMappingToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_list_mapping, :text

    # set default value in MySQL, ref: https://github.com/KKBOX/redmine-trello-card-sync/issues/16
    Project.all.each do |p|
      p.trello_list_mapping = ""
      p.save!
    end
  end
end