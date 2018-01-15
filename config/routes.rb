# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  scope '/projects/:project_id/trello_card_sync' do
    resources :mappings do
      collection do
        patch 'save'
      end
    end
  end

  resources :trello_webhooks, only: [:index, :create]
end
