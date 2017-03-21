class AddTrelloBoardMappingToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_mapping_redmine_statuses, :text, :default => "", :null => false
    add_column :projects, :trello_mapping_trello_lists,     :text, :default => "", :null => false
  end
end
