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

  get  :trello_webhooks, to: 'trello_webhooks#index'
  post :trello_webhooks, to: 'trello_webhooks#update_redmine_issue'
end
