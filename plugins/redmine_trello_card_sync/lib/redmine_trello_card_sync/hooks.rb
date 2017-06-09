require 'trello'

# TrelloCardSyncHook - Sync an issue to a Trello card
class TrelloCardSyncHook < Redmine::Hook::Listener
  def initialize
    @plugin_ready = false

    Trello.configure do |config|
      config.developer_public_key = Setting.plugin_redmine_trello_card_sync[:public_key].strip
      config.member_token = Setting.plugin_redmine_trello_card_sync[:member_token].strip
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
    issue = context[:issue]
    begin
      status_syncing(issue) if @plugin_ready
    rescue StandardError => e
      Rails.logger.error(e.to_s)
    end
  end

  def controller_issues_edit_after_save(context = {})
    issue = context[:issue]
    begin
      status_syncing(issue) if @plugin_ready
    rescue StandardError => e
      Rails.logger.error(e.to_s)
    end
  end

  private

  def status_syncing(issue)
    project = issue.project

    unless project.trello_board_sync
      Rails.logger.info("[Trello] This project doesn't enable sync. Skip.")
      return true
    end

    unless project.trello_board_id.present?
      Rails.logger.info("[Trello] This project doesn't provide a board ID. Skip.")
      return true
    end

    board = Trello::Board.find(project.trello_board_id.strip)

    # find out the target list
    target_list = nil

    redmine_statuses = project.trello_mapping_redmine_statuses.split(/\n+/).map(&:strip).reject(&:blank?).uniq
    trello_lists = project.trello_mapping_trello_lists.split(/\n+/).map(&:strip).reject(&:blank?)
    status_map = status_mapping(board, redmine_statuses, trello_lists)
    target_list = status_map[issue.status.name]

    if target_list.nil?
      Rails.logger.info('[Trello] No valid mapping. Skip.')
      return true
    end

    Rails.logger.info("[Trello] Status mapping: '#{issue.status.name}' -> '#{target_list}'")

    # Sync ticket & card
    card_name = "##{issue.id} #{issue.subject}"
    card = board.cards.find { |c| c.name == card_name }

    if target_list == '//close'
      unless card.nil?
        Rails.logger.info("[Trello] Closing card: #{card_name}")
        card.close!
      end
    else
      Rails.logger.info("[Trello] Processing card: #{card_name}")
      list = board.lists.find { |l| l.name == target_list }
      if list.nil?
        Rails.logger.error("Invalid list: #{target_list}")
        return false
      end
      if card.nil?
        card = Trello::Card.create(name: card_name, list_id: list.id)
      else
        card.move_to_list(list)
      end
    end

    # Sync ticket assignee & card member
    if card.nil?
      Rails.logger.info('[Trello] No such card. Skip.')
      return true
    end

    if issue.assigned_to.nil?
      Rails.logger.info("[Trello] The Redmine issue doesn't have assignee. Skip.")
      return true
    end

    if issue.assigned_to.trello_username.blank?
      Rails.logger.info("[Trello] User doesn't have Trello username. Skip.")
      return true
    end

    trello_member = board.members.find { |b| b.username == issue.assigned_to.trello_username.strip }

    if trello_member.nil?
      Rails.logger.info('[Trello] Wrong Trello username. Skip.')
      return true
    end

    card.add_member(trello_member) unless card.members.include? trello_member
  end

  def status_mapping(board, redmine_statuses, trello_lists)
    if redmine_statuses.size != trello_lists.size
      raise("Unequal mapping number. R: #{redmine_statuses.size} T: #{trello_lists.size}")
    end

    # statuses checking
    valid_statuses = IssueStatus.all.collect(&:name)
    redmine_statuses.each do |rs|
      unless valid_statuses.include?(rs)
        raise("Found invalid status in plugin settings: #{rs}")
      end
    end if redmine_statuses.size > 0

    # list checking (in default board)
    valid_lists = board.lists.collect(&:name)
    valid_lists << '//close'
    trello_lists.each do |tl|
      unless valid_lists.include?(tl)
        raise("Found invalid list in plugin settings: #{tl}")
      end
    end if trello_lists.size > 0

    # finally ensure that we can build a valid status map
    status_map = Hash[redmine_statuses.zip(trello_lists)]
    status_map
  end
end
