class AddTrelloBoardMappingToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_mapping_redmine_statuses, :text, :null => false
    add_column :projects, :trello_mapping_trello_lists,     :text, :null => false
  end
end
