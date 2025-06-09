class CommitMetadatum < ApplicationRecord
  has_many :comments, class_name: 'CommitComment', dependent: :destroy
  has_many :jira_tickets, dependent: :destroy
  
  validates :sha, :repo_owner, :repo_name, presence: true
  validates :sha, uniqueness: { scope: [:repo_owner, :repo_name] }

  # Parses Jira ticket numbers from commit message and creates associations
  def parse_jira_tickets(message)
    return unless message.present?
    
    # Extract Jira ticket numbers (format: ABC-123)
    ticket_numbers = message.scan(/\b([A-Z]{2,}-\d+)\b/).flatten.uniq
    
    ticket_numbers.each do |ticket_number|
      jira_tickets.find_or_create_by(ticket_number: ticket_number)
    end
  end
end
