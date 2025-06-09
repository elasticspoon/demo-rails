class JiraTicket < ApplicationRecord
  belongs_to :commit_metadata

  validates :ticket_number, presence: true

  def url
    "https://jira.example.com/browse/#{ticket_number}"
  end
end
