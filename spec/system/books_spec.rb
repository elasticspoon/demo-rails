require 'rails_helper'
require 'playwright/test'

RSpec.describe "Books", type: :system do
  include Playwright::Test::Matchers
  it "works" do
    visit root_path

    expect(page).to have_text("Books")
  end
end
