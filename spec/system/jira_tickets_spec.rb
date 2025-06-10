require 'rails_helper'

RSpec.describe 'Jira Tickets', type: :system do
  let(:commit) { create(:commit) }
  let(:metadata) { create(:commit_metadatum, commit: commit) }

  before do
    driven_by(:selenium_chrome_headless)
    visit commits_path
  end

  describe 'adding tickets' do
    context 'with valid input' do
      it 'adds the ticket to the table' do
        within("#commit_#{metadata.id}_jira_tickets") do
          click_link 'Add Ticket'
        end

        expect(page).to have_css('input[name="jira_ticket[ticket_number]"]')

        within("##{metadata.id}_jira_tickets_table tr:last-child") do
          fill_in 'jira_ticket[ticket_number]', with: 'TEST-123'
          click_button 'Save'
        end

        expect(page).to have_content('TEST-123')
        expect(page).to have_link('Add Ticket')
      end

      it 'creates the table when first ticket is added' do
        expect(page).not_to have_css("##{metadata.id}_jira_tickets_table")

        within("#commit_#{metadata.id}_jira_tickets") do
          click_link 'Add Ticket'
        end

        within("##{metadata.id}_jira_tickets_table tr:last-child") do
          fill_in 'jira_ticket[ticket_number]', with: 'TEST-456'
          click_button 'Save'
        end

        expect(page).to have_css("##{metadata.id}_jira_tickets_table")
        expect(page).to have_content('TEST-456')
      end
    end

    context 'with invalid input' do
      it 'shows validation errors' do
        within("#commit_#{metadata.id}_jira_tickets") do
          click_link 'Add Ticket'
        end

        within("##{metadata.id}_jira_tickets_table tr:last-child") do
          fill_in 'jira_ticket[ticket_number]', with: ''
          click_button 'Save'
        end

        expect(page).to have_css('.usa-error-message', text: "can't be blank")
        expect(page).to have_button('Save') # form remains open
      end
    end
  end

  describe 'editing tickets' do
    let!(:ticket) { create(:jira_ticket, commit_metadata: metadata, ticket_number: 'OLD-123') }

    before do
      visit commits_path
    end

    it 'updates the ticket' do
      within("##{dom_id(ticket)}") do
        click_link 'Edit'
      end

      within("##{dom_id(ticket)}") do
        fill_in 'jira_ticket[ticket_number]', with: 'NEW-456'
        click_button 'Save'
      end

      expect(page).to have_content('NEW-456')
      expect(page).not_to have_content('OLD-123')
    end

    it 'shows validation errors' do
      within("##{dom_id(ticket)}") do
        click_link 'Edit'
      end

      within("##{dom_id(ticket)}") do
        fill_in 'jira_ticket[ticket_number]', with: ''
        click_button 'Save'
      end

      expect(page).to have_css('.usa-error-message', text: "can't be blank")
      expect(page).to have_button('Save') # form remains open
    end
  end

  describe 'deleting tickets' do
    let!(:ticket) { create(:jira_ticket, commit_metadata: metadata) }

    before do
      visit commits_path
    end

    it 'removes the ticket' do
      within("##{dom_id(ticket)}") do
        click_button 'Delete'
      end

      accept_confirm do
        # Confirm deletion
      end

      expect(page).not_to have_content(ticket.ticket_number)
    end

    it 'removes the table when last ticket is deleted' do
      within("##{dom_id(ticket)}") do
        click_button 'Delete'
      end

      accept_confirm do
        # Confirm deletion
      end

      expect(page).not_to have_css("##{metadata.id}_jira_tickets_table")
    end
  end
end
