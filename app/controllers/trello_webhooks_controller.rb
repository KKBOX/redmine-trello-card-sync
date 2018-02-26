require 'openssl'
require 'base64'

# Trello webhooks (Sync from Trello to Redmine)
class TrelloWebhooksController < ApplicationController
  unloadable
  skip_before_action :check_if_login_required
  skip_before_action :authenticate
  skip_before_action :verify_authenticity_token

  def index
    render status: 200, json: { status: 'ok' }
  end

  def update_redmine_issue
    @webhooks_request = TrelloWebhooksHelper::WebhooksRequest.new(request)
    logger.info("[Trello] Webhook payload: #{@webhooks_request.payload}")

    unless @webhooks_request.valid_request?
      logger.info('[Trello] Mismatched signature, maybe a fake reqest or you have a wrong API secret.')
      render(status: 403, json: { status: 'error', message: 'Mismatched signature, maybe a fake reqest.' }) && (return true)
    end

    if @webhooks_request.payload['action']['type'] == 'updateCard'
      issue_data = /^\#(?<issue_number>\d+)\s(?<issue_subject>.*)/.match(@webhooks_request.payload['action']['data']['card']['name'])
      issue = Issue.find(issue_data[:issue_number])

      if issue.nil?
        render(status: 500, json: { status: 'error', message: 'Unable to find the Redmine issue.' }) && (return true)
      end

      # reversal sync: card.name -> issue.subject
      if @webhooks_request.payload['action']['data']['old']['name']
        # avoids potential circular update
        if issue.subject != issue_data[:issue_subject]
          issue.subject = issue_data[:issue_subject]
        end
      end

      # reversal sync: card.desc -> issue.description
      if @webhooks_request.payload['action']['data']['old']['desc']
        new_desc = @webhooks_request.payload['action']['data']['card']['desc']
        issue.description = new_desc if issue.description != new_desc
      end

      # reversal sync: card.due -> issue.due_date
      if @webhooks_request.payload['action']['data']['old']['due']
        new_due = @webhooks_request.payload['action']['data']['card']['due']
        issue.due_date = Date.parse(new_due) if issue.due_date != new_due
      end

      # reversal sync: card.move_to_list(idList) -> issue.status.id
      if @webhooks_request.payload['action']['data']['old']['idList']
        list_mapping = Hash[JSON.load(issue.project.trello_list_mapping).map { |k, v| [k.to_i, v.to_s] }]
        new_list_id = @webhooks_request.payload['action']['data']['card']['idList']
        new_stat_id = list_mapping.select { |_k, v| v == new_list_id }.keys.first
        if new_stat_id.present? && issue.status_id != new_stat_id
          issue.status_id = new_stat_id
        end
      end

      logger.info("[Trello] Saving issue #{issue.id}...")
      issue.save!
    end

    render status: 200, json: { status: 'ok' }
  end
end
