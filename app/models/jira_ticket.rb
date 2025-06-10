class JiraTicket < ApplicationRecord
  belongs_to :commit_metadata, foreign_key: "commit_metadata_id", class_name: "CommitMetadatum"
  validates :ticket_number, presence: true

  def url
    "https://jira.example.com/browse/#{ticket_number}"
  end

  # Dummy methods for now - will replace with real data later
  def state
    ["Open", "In Progress", "Done"].sample
  end

  def author
    ["Dev Team", "QA Team", "Product"].sample
  end
end
