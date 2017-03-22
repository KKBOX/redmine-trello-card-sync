class AddTrelloBoardMappingToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_mapping_redmine_statuses, :text, :default => nil
    add_column :projects, :trello_mapping_trello_lists,     :text, :default => nil
  end
end
