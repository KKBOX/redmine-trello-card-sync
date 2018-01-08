require 'trello'

# TrelloCardSyncHook - Sync an issue to a Trello card
class TrelloCardSyncHook < Redmine::Hook::Listener
  def initialize
    @plugin_ready = false

    Trello.configure do |config|
      config.developer_public_key = Setting.plugin_redmine_trello_card_sync['public_key'].present? ? Setting.plugin_redmine_trello_card_sync['public_key'].strip : ''
      config.member_token = Setting.plugin_redmine_trello_card_sync['member_token'].present? ? Setting.plugin_redmine_trello_card_sync['member_token'].strip : ''
    end

    begin
      # Just a 'ping' purpose API call, for ensure that we've configured Trello client well.
      boards = Trello::Board.all
      @plugin_ready = true
    rescue StandardError => e
      Rails.logger.error(e.to_s)
    end

    Rails.logger.info("[Trello] Is TrelloCardSync plugin ready? #{@plugin_ready}")
  end

  def controller_issues_new_after_save(context = {})
    begin
      status_syncing(context) if @plugin_ready
    rescue StandardError => e
      Rails.logger.error(e.to_s)
    end
  end

  def controller_issues_edit_after_save(context = {})
    begin
      status_syncing(context) if @plugin_ready
    rescue StandardError => e
      Rails.logger.error(e.to_s)
    end
  end

  private

  def status_syncing(context)
    request = context[:request] unless context[:request].nil?
    issue = context[:issue]
    project = issue.project

    if !project.module_enabled?("trello_card_sync")
      raise "[Trello] This project doesn't enable sync module. Skip."
    end

    trello_excluded_trackers = eval(project.trello_excluded_trackers_v2).reject(&:empty?).map(&:to_i)
    if trello_excluded_trackers.include?(issue.tracker_id)
      raise "[Trello] The tracker of this issue doesn't enable sync. Skip."
    end

    if !project.trello_board_id.present?
      raise "[Trello] This project doesn't provide a board ID. Skip."
    end

    board = Trello::Board.find(project.trello_board_id.strip)
    list_mapping = Hash[eval(project.trello_list_mapping).map { |k, v| [k.to_i, v.to_s] }]
    list_id = list_mapping[issue.status.id]

    # ""
    if !list_id.present?
      raise "[Trello] No mapping list was assigned for this status. Skip."
    end

    # Sync ticket & card
    card_name = "##{issue.id} #{issue.subject}"
    # search card as title pattern: "#issue_no issue_title"
    card = board.cards.find { |c| /^\##{issue.id}*\s.*/.match(c.name) }

    if list_id == '//close'
      unless card.nil?
        Rails.logger.info("[Trello] Closing card: #{card_name}")
        card.close!
      end
    else
      target_list = Trello::List.find(list_id)
      Rails.logger.info("[Trello] Processing card: #{card_name}")
      Rails.logger.info("[Trello] Status mapping: '#{issue.status.name}' -> '#{target_list.name}'")
      if card.nil?
        card = Trello::Card.create(name: card_name, list_id: target_list.id)
      else
        card.name = card_name
        card.update!
        card.move_to_list(target_list)
      end
    end

    # Sync ticket assignee, card member, due date & descritpion

    # Don't process closed cards:
    if card.nil?
      raise "[Trello] No such card. Skip."
    end

    # sync due date
    unless issue.due_date.nil?
      card.due = issue.due_date.to_time
      card.update!
    end

    # sync description
    if request
      issue_url = "#{request.protocol}#{request.host_with_port}/issues/#{issue.id}"
      card.desc = "#{issue.description}\n\n**🔗 Redmine Issue:** #{issue_url}".strip
    else
      card.desc = "#{issue.description}".strip
    end
    card.update!

    # sync assignee
    if issue.assigned_to.nil?
      raise "[Trello] The Redmine issue doesn't have assignee. Skip."
    else
      if issue.assigned_to.trello_username.blank?
        raise "[Trello] User doesn't have Trello username. Skip."
      end

      trello_member = board.members.find { |b| b.username == issue.assigned_to.trello_username.strip }

      if trello_member.nil?
        raise '[Trello] Wrong Trello username. Skip.'
      end

      card.add_member(trello_member) unless card.members.include? trello_member
    end
  end
end
