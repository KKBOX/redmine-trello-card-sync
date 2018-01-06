require 'trello'

class MappingsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :setup_trello_api

  def index
    # "//close" => Our special magic option to close (archive) the card
    @extra_close_option = [l(:trello_card_sync_close_option), '//close']
    @board_lists = Trello::Board.find(@project.trello_board_id).lists.map { |list| [list.name, list.id] }
    @board_lists << @extra_close_option
    @excluded_trackers = excluded_trackers
  end

  def show
  end

  def edit
  end

  def update
  end

  private

  def excluded_trackers
    JSON.parse(@project.trello_excluded_trackers).reject { |tracker| tracker.empty? }.map { |tracker| tracker.to_i }
  end

  def setup_trello_api
    Trello.configure do |config|
      config.developer_public_key = Setting.plugin_redmine_trello_card_sync['public_key'].present? ? Setting.plugin_redmine_trello_card_sync['public_key'].strip : ''
      config.member_token = Setting.plugin_redmine_trello_card_sync['member_token'].present? ? Setting.plugin_redmine_trello_card_sync['member_token'].strip : ''
    end
  end
end
