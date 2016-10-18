class AddTrelloUsernameToUser < ActiveRecord::Migration
  def change
    add_column :users, :trello_username, :string, :default => "", :null => false
  end
end
