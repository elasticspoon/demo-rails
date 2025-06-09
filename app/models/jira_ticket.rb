class JiraTicket < ApplicationRecord
  belongs_to :commit_metadatum
  
  validates :ticket_number, presence: true, 
    format: { with: /\A[A-Z]+-\d+\z/, message: "must be in format ABC-123" }
    
  def url
    "https://jira.example.com/browse/#{ticket_number}"
  end
end
