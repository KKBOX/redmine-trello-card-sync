require 'redmine'

Redmine::Plugin.register :redmine_trello_card_sync do
  name 'Trello card sync plugin'
  author 'Hiroshi Yui'
  description 'Sync Redmine ticket to Trello card'
  version '0.0.4'
  url 'https://github.com/hiroshiyui/redmine_trello_card_sync'
  author_url 'https://ghostsinthelab.org/'
  requires_redmine :version_or_higher => '2.3.2'

  Rails.configuration.to_prepare do
    require_dependency 'redmine_trello_card_sync/hooks'
    require_dependency 'redmine_trello_card_sync/view_hooks'
    require_dependency 'redmine_trello_card_sync/project_patch'
    Project.send(:include, TrelloCardSync::Patches::ProjectPatch)
    User.send(:include, TrelloCardSync::Patches::UserPatch)
  end

  settings :default => {:public_key => '', :member_token => '', :board_id => '', :redmine_statuses => '', :trello_lists => ''}, :partial => 'settings/trello_sync_settings'
end
