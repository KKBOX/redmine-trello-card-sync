require 'trello'

# Mappings maintenance
class MappingsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :setup_trello_api

  def index
    @board_lists = []
    if @project.trello_board_id.present?
      # "//close" => Our special magic option to close (archive) the card
      @extra_close_option = [l(:trello_card_sync_close_option), '//close']
      @board_lists = Trello::Board.find(@project.trello_board_id).lists.map { |list| [list.name, list.id] }
      @board_lists << @extra_close_option
    else
      flash[:warning] = t(:trello_card_sync_no_board_specified_warning, project: @project.name)
    end
    @excluded_trackers = excluded_trackers
    @excluded_trackers_v2 = excluded_trackers_v2
    @list_mapping = list_mapping
  end

  def save
    @project.trello_board_id = params[:project][:trello_board_id]
    @project.trello_excluded_trackers = params[:project][:trello_excluded_trackers].to_s
    @project.trello_excluded_trackers_v2 = params[:project][:trello_excluded_trackers].to_json
    @project.trello_list_mapping = params[:trello_list_mapping].to_json
    @project.trello_enable_bidirectional_sync = params[:project][:trello_enable_bidirectional_sync].to_i
    @project.save!

    # Check & create webhooks
    registered_webhook = nil
    trello_board_info = ''
    if @project.trello_board_id.present?
      token = Trello::Token.find( Setting.plugin_redmine_trello_card_sync['member_token'] )
      registered_webhook = token.webhooks.find { |whk| whk['idModel'] == @project.trello_board_id }
      trello_board_info = "'#{Trello::Board.find( @project.trello_board_id ).name}' (#{@project.trello_board_id})"
    end

    if @project.trello_enable_bidirectional_sync
      logger.info('[Trello] Bidirectional sync is enabled')

      if registered_webhook.nil?
        # create webhook
        logger.info("[Trello] Creating webhook for #{trello_board_info}")
        description = "Webhook for #{trello_board_info}"
        callback_url = Setting.plugin_redmine_trello_card_sync['webhooks_url']
        id_model = @project.trello_board_id
        begin
          binding.pry
          Trello::Webhook.create(description: description, callback_url: callback_url, id_model: id_model)
        rescue StandardError => e
          logger.error("[Trello] Oops! Failed to register the webhook: #{e.to_s}")
        end
      else
        logger.info("[Trello] Webhook has existed for board #{trello_board_info}")
      end
    else
      logger.info('[Trello] Bidirectional sync is disabled. Check if we have to delete the related Trello webhook.')

      #   * Check if there are no more Redmine projects that need bidirectional sync to the Trello board
      #   * If yes, remove the registered webhook
      if registered_webhook
        if Project.all.find { |p| p.trello_board_id == @project.trello_board_id && p.trello_enable_bidirectional_sync }
          logger.info('[Trello] There is some project that is keep using bidirectional sync, do not un-register webhook.')
        else
          webhook = Trello::Webhook.find( registered_webhook['id'] )
          webhook.delete
          logger.info('[Trello] Webhook has been unregistered.')
        end
      else
        logger.info('[Trello] There is no project that has registered a webhook.')
      end
    end

    redirect_to mappings_url, notice: l(:trello_card_sync_settings_saved)
  rescue StandardError => e
    logger.error(e.to_s)
    redirect_to mappings_url, alert: e.to_s
  end

  private

  def excluded_trackers
    JSON.parse(@project.trello_excluded_trackers).reject(&:empty?).map(&:to_i)
  end

  def excluded_trackers_v2
    if @project.trello_excluded_trackers.present? && !@project.trello_excluded_trackers_v2.present?
      @project.trello_excluded_trackers_v2 = JSON.parse(@project.trello_excluded_trackers).to_json
      @project.save!
    end
    JSON.load(@project.trello_excluded_trackers_v2).reject(&:empty?).map(&:to_i)
  end

  def list_mapping
    list_mapping = {}
    if @project.trello_list_mapping.present?
      list_mapping = Hash[JSON.load(@project.trello_list_mapping).map { |k, v| [k.to_i, v.to_s] }]
    end
    list_mapping
  end

  def setup_trello_api
    Trello.configure do |config|
      config.developer_public_key = Setting.plugin_redmine_trello_card_sync['public_key'].present? ? Setting.plugin_redmine_trello_card_sync['public_key'].strip : ''
      config.member_token = Setting.plugin_redmine_trello_card_sync['member_token'].present? ? Setting.plugin_redmine_trello_card_sync['member_token'].strip : ''
    end
  end
end
