require 'openssl'
require 'base64'

class TrelloWebhooksController < ApplicationController
  unloadable
  skip_before_action :authenticate
  skip_before_action :verify_authenticity_token

  def index
    render status: 200, json: { status: 'ok' }
  end

  def create
    payload = JSON.parse(request.raw_post)
    payload_signature = request.headers['X-Trello-Webhook']
    sig_verify_data = request.raw_post + request.original_url
    sig_digest = signature_base64_digest(sig_verify_data).strip

    logger.info("Webhook payload: #{payload}")
    logger.info(request.headers.inspect)

    # TODO: request.remote_ip white listing (optional)

    if payload_signature != sig_digest
      logger.info("Mismatched signature, maybe a fake reqest or you have a wrong API secret.")
      render status: 403, json: { status: 'error', message: 'Mismatched signature, maybe a fake reqest.' }
    end

    render status: 200, json: { status: 'ok' }
  end

  private

  def signature_base64_digest(data)
    # ref: https://developers.trello.com/v1.0/page/webhooks#section-webhook-signatures
    Base64.encode64(OpenSSL::HMAC.digest('sha1', trello_api_secret, data))
  end

  def trello_api_secret
    trello_api_secret = Setting.plugin_redmine_trello_card_sync['api_secret'].present? ? Setting.plugin_redmine_trello_card_sync['api_secret'].strip : ''
  end
end
