module TrelloCardSyncProjectExtension
  extend ActiveSupport::Concern
  included do
    has_many :mappings, :class_name => "TrelloCardSyncMapping", :foreign_key => "project_id"
  end
end
