class JiraTicket < ApplicationRecord
  belongs_to :commit_metadata, foreign_key: "commit_metadata_id", class_name: "CommitMetadatum"
  validates :ticket_number, presence: true

  def url
    "https://jira.example.com/browse/#{ticket_number}"
  end
end
