module TrelloCardSync
  module Patches
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          safe_attributes 'trello_board_id', 'trello_board_sync', 'trello_mapping_redmine_statuses', 'trello_mapping_trello_lists', 'trello_excluded_trackers'
        end
      end
    end
    module UserPatch
      def self.included(base)
        base.class_eval do
          safe_attributes 'trello_username'
        end
      end
    end
  end
end
