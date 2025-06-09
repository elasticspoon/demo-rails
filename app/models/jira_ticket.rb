class JiraTicket < ApplicationRecord
  belongs_to :commit_metadatum, foreign_key: 'commit_metadata_id'
  validates :ticket_number, presence: true

  def url
    "https://jira.example.com/browse/#{ticket_number}"
  end
end
