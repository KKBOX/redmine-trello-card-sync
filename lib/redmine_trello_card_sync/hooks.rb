require 'trello'

class TrelloCardSyncHook < Redmine::Hook::Listener
  def initialize
    @@plugin_ready = false
    begin
      Trello.configure do |config|
        config.developer_public_key = Setting.plugin_redmine_trello_card_sync[:public_key]
        config.member_token = Setting.plugin_redmine_trello_card_sync[:member_token]
      end
      @@board = Trello::Board.find( Setting.plugin_redmine_trello_card_sync[:board_id] )

      # It's an one-to-many relation
      @@redmine_statuses = Setting.plugin_redmine_trello_card_sync[:redmine_statuses].split(/\n+/).map {|rs| rs.strip}.reject(&:blank?).uniq
      @@trello_lists = Setting.plugin_redmine_trello_card_sync[:trello_lists].split(/\n+/).map {|tl| tl.strip}.reject(&:blank?)
      @@status_map = status_mapping(@@board, @@redmine_statuses, @@trello_lists)

      @@plugin_ready = true
    rescue Exception => e
      Rails.logger.error("#{e}")
    end

    Rails.logger.info("[Trello] Is TrelloCardSync plugin ready? #{@@plugin_ready}")
  end

  def controller_issues_new_after_save(context={})
    issue = context[:issue]
    begin
      status_syncing(issue) if @@plugin_ready
    rescue Exception => e
      Rails.logger.error("#{e}")
    end
  end

  def controller_issues_edit_after_save(context={})
    issue = context[:issue]
    begin
      status_syncing(issue) if @@plugin_ready
    rescue Exception => e
      Rails.logger.error("#{e}")
    end
  end

  private
  def status_syncing(issue)
    project = issue.project

    unless project.trello_board_sync
      Rails.logger.info("[Trello] This project does't enable sync. Skip.")
      return true
    end

    # default Trello board
    board = @@board
    if project.trello_board_id.present?
      board = Trello::Board.find( project.trello_board_id.strip )
    end

    # find out the target list
    target_list = nil
    if project.trello_mapping_redmine_statuses.blank? || project.trello_mapping_trello_lists.blank?
      target_list = @@status_map[issue.status.name]
    else
      redmine_statuses = project.trello_mapping_redmine_statuses.split(/\n+/).map {|rs| rs.strip}.reject(&:blank?).uniq
      trello_lists = project.trello_mapping_trello_lists.split(/\n+/).map {|tl| tl.strip}.reject(&:blank?)
      status_map = status_mapping(board, redmine_statuses, trello_lists)
      target_list = status_map[issue.status.name]
    end

    if target_list.nil?
      Rails.logger.info("[Trello] No valid mapping. Skip.")
      return true
    end

    Rails.logger.info("[Trello] Status mapping: '#{issue.status.name}' -> '#{target_list}'")

    # Sync ticket & card
    card_name = "##{issue.id} #{issue.subject}"
    card = board.cards.select { |c| c.name == card_name }.first

    if target_list == "//close"
      unless card.nil?
        Rails.logger.info("[Trello] Closing card: #{card_name}")
        card.close!
      end
    else
      Rails.logger.info("[Trello] Processing card: #{card_name}")
      list = board.lists.select { |l| l.name == target_list }.first
      if list.nil?
        Rails.logger.error("Invalid list: #{target_list}")
        return false
      end
      if card.nil?
        card = Trello::Card.create({ :name => card_name, :list_id => list.id })
      else
        card.move_to_list(list)
      end
    end

    # Sync ticket assignee & card member
    if card.nil?
      Rails.logger.info("[Trello] No such card. Skip.")
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

    trello_member = board.members.select { |b| b.username == issue.assigned_to.trello_username.strip }.first

    if trello_member.nil?
      Rails.logger.info("[Trello] Wrong Trello username. Skip.")
      return true
    end

    unless card.members.include? trello_member
      card.add_member(trello_member)
    end
  end

  def status_mapping(board, redmine_statuses, trello_lists)
    if redmine_statuses.size != trello_lists.size
      raise("Unequal mapping number. R: #{redmine_statuses.size} T: #{trello_lists.size}")
    end

    # statuses checking
    valid_statuses = IssueStatus.all.collect {|is| is.name}
    redmine_statuses.each do |rs|
      unless valid_statuses.include?(rs)
        raise("Found invalid status in plugin settings: #{rs}")
      end
    end if redmine_statuses.size > 0

    # list checking (in default board)
    valid_lists = board.lists.collect {|l| l.name}
    valid_lists << "//close"
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
