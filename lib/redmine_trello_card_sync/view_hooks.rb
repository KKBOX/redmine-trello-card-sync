class TrelloCardSyncViewHook < Redmine::Hook::ViewListener
  render_on(:view_layouts_base_html_head, :inline => "<%= stylesheet_link_tag 'trello_card_sync', :plugin => :redmine_trello_card_sync %>")
  render_on(:view_users_form, partial: 'users/redmine_trello_card_sync', layout: false)
  render_on(:view_my_account, partial: 'users/redmine_trello_card_sync', layout: false)
end
