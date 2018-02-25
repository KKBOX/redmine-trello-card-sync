module TrelloWebhooksHelper
  class WebhooksRequest
    attr_accessor :payload, :raw_payload, :signature, :digest
    def initialize(request)
      @raw_payload = request.raw_post
      @payload = JSON.parse(request.raw_post)
      @original_url = request.original_url
      @signature = request.headers['X-Trello-Webhook']
    end

    def digest
      signature_base64_digest(@raw_payload + @original_url).strip
    end

    def valid_request?
      @signature_base64_digest == @digest
    end

    private

    def signature_base64_digest(data)
      # ref: https://developers.trello.com/v1.0/page/webhooks#section-webhook-signatures
      trello_api_secret = Setting.plugin_redmine_trello_card_sync['api_secret'].present? ? Setting.plugin_redmine_trello_card_sync['api_secret'].strip : ''
      Base64.encode64(OpenSSL::HMAC.digest('sha1', trello_api_secret, data))
    end
  end
end
