require 'rails_helper'

RSpec.describe CommitMetadatum, type: :model do
  describe '#parse_jira_tickets' do
    let(:metadata) { create(:commit_metadatum) }
    
    it 'creates Jira tickets from commit message' do
      message = "Fix PROJ-123 and PROJ-456 issues"
      expect {
        metadata.parse_jira_tickets(message)
      }.to change(metadata.jira_tickets, :count).by(2)
      
      expect(metadata.jira_tickets.pluck(:ticket_number)).to match_array(['PROJ-123', 'PROJ-456'])
    end

    it 'handles messages without Jira tickets' do
      expect {
        metadata.parse_jira_tickets("Regular commit message")
      }.not_to change(metadata.jira_tickets, :count)
    end

    it 'ignores duplicate tickets in same message' do
      message = "PROJ-123 PROJ-123 PROJ-123"
      expect {
        metadata.parse_jira_tickets(message)
      }.to change(metadata.jira_tickets, :count).by(1)
    end
  end
end
