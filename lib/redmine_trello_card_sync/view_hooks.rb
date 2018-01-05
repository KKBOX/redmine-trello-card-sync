class TrelloCardSyncViewHook < Redmine::Hook::ViewListener
  render_on(:view_users_form, partial: 'users/redmine_trello_card_sync', layout: false)
  render_on(:view_my_account, partial: 'users/redmine_trello_card_sync', layout: false)
end
