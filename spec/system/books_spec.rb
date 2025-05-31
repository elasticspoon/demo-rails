require 'rails_helper'

RSpec.describe "Books", type: :system do
  it "works" do
    visit root_path

    expect(page).to have_text("Books")
  end
end
