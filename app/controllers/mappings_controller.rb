require 'trello'

class MappingsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :setup_trello_api

  def index
    @trello_board_lists = Trello::Board.find(@project.trello_board_id).lists
  end

  def show
  end

  def edit
  end

  def update
  end

  private

  def setup_trello_api
    Trello.configure do |config|
      config.developer_public_key = Setting.plugin_redmine_trello_card_sync['public_key'].present? ? Setting.plugin_redmine_trello_card_sync['public_key'].strip : ''
      config.member_token = Setting.plugin_redmine_trello_card_sync['member_token'].present? ? Setting.plugin_redmine_trello_card_sync['member_token'].strip : ''
    end
  end
end
