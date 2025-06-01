require 'rails_helper'
require 'playwright/test'

RSpec.describe "Books", type: :system do
  it "works" do
    visit root_path

    expect(page).to have_text("Books")
  end

  describe do
    include Playwright::Test::Matchers

    it "fails" do
      visit root_path

      Capybara.current_session.driver.with_playwright_page do |page|
        expect(page.locator("html")).to have_text("Books")
      end

      aggregate_failures do
        expect(page.find('body')).to have_text("Books")
        within 'html' do
          within 'body' do
            expect(page).to have_text("Books")
          end
        end
        within 'body' do
          expect(page).to have_text("Books")
        end
        expect(page).to have_text("Books")
      end
    end
  end
end
