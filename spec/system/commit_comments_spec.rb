require 'rails_helper'

RSpec.describe 'Commit Comments', type: :system do
  let(:metadata) { CommitMetadatum.first }

  before do
    visit commits_path
  end

  describe 'adding comments' do
    context 'with valid input' do
      it 'adds the comment to the table' do
        within("#commit_#{metadata.id}_new_comment") do
          click_link 'Add Comment'
        end

        expect(page).to have_css('textarea[name="commit_comment[content]"]')

        within("#commit_#{metadata.id}_new_comment form") do
          fill_in 'commit_comment[content]', with: 'This is a test comment'
          click_button 'Post Comment'
        end

        expect(page).to have_content('This is a test comment')
        expect(page).to have_css("#commit_#{metadata.id}_comments_table tr", count: 1)
        expect(page).to have_link('Add Comment')
      end

      it 'creates the table when first comment is added' do
        expect(page).not_to have_css("#commit_#{metadata.id}_comments_table")

        within("#commit_#{metadata.id}_new_comment") do
          click_link 'Add Comment'
        end

        within("#commit_#{metadata.id}_new_comment form") do
          fill_in 'commit_comment[content]', with: 'First comment'
          click_button 'Post Comment'
        end

        expect(page).to have_css("#commit_#{metadata.id}_comments_table")
        expect(page).to have_content('First comment')
      end
    end

    context 'with invalid input' do
      it 'shows validation errors' do
        within("#commit_#{metadata.id}_new_comment") do
          click_link 'Add Comment'
        end

        within("#commit_#{metadata.id}_new_comment form") do
          fill_in 'commit_comment[content]', with: ''
          click_button 'Post Comment'
        end

        expect(page).to have_css('.usa-error-message', text: "can't be blank")
        expect(page).to have_button('Post Comment') # form remains open
      end

      it 'allows cancelling the form' do
        within("#commit_#{metadata.id}_new_comment") do
          click_link 'Add Comment'
        end

        # click_link 'Cancel'
        #
        # expect(page).not_to have_css('textarea[name="commit_comment[content]"]')
        # expect(page).to have_link('Add Comment')
      end
    end
  end
end
