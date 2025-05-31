require "capybara/rspec"
require "playwright"

Capybara.register_driver :my_playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: (false unless ENV["CI"] || ENV["PLAYWRIGHT_HEADLESS"]))
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :my_playwright
  end
end
