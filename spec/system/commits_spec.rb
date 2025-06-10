require 'rails_helper'

RSpec.describe 'Commits', type: :system do
  let(:commit) do
    Commit.new(
      sha: '6bb54ac227c1f4ee693db4f778be403675188a07',
      message: 'Merge pull request #6412',
      author_name: 'compwron',
      date: Time.parse('2025-06-05T14:23:38Z'),
      url: 'https://github.com/rubyforgood/casa/commit/6bb54ac227c1f4ee693db4f778be403675188a07'
    )
  end

  before do
    allow_any_instance_of(CommitService).to receive(:recent_commits).and_return([ commit ])
    visit commits_path
  end

  it 'displays commit data in key-value table format' do
    within '.usa-card' do
      expect(page).to have_css('table.usa-table--borderless')
      expect(page).to have_css('td.text-bold', text: 'Author:')
      expect(page).to have_css('td', text: commit.author_name)
      expect(page).to have_css('td.text-bold', text: 'Date:')
      expect(page).to have_css('td', text: commit.formatted_date)
      expect(page).to have_css('td.text-bold', text: 'SHA:')
      expect(page).to have_css('td.font-mono-2xs', text: commit.sha)

      # Verify button group
      expect(page).to have_css('.usa-button-group')
      expect(page).to have_link('View on GitHub',
        href: commit.url,
        class: 'usa-button--outline')
    end
  end
end
