class AddTrelloListMappingToProject < ActiveRecord::Migration
  def change
    add_column :projects, :trello_list_mapping, :text, :default => "", :null => false
  end
end