# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  scope '/projects/:project_id/trello_card_sync' do
    resources :mappings
  end
end
