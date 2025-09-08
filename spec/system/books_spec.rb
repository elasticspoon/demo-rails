require 'rails_helper'
require 'playwright/test'

RSpec.describe "Books", type: :system do
  it "works" do
    visit root_path

    expect(page).to have_text("Books")
  end

  describe do
    it "fails" do
      visit root_path

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
