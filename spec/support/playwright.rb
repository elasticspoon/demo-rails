require "capybara/rspec"
require "playwright"
require "playwright/test"

Capybara.register_driver :my_playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: (true unless ENV["SHOW_CHROME"]))
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :my_playwright
  end
end

Playwright::Test::Expect.prepend(Module.new do
  def call(actual, is_not)
    case actual
    when Playwright::Page
      Playwright::PageAssertions.new(
        Playwright::PageAssertionsImpl.new(
          actual,
          @timeout_settings.timeout,
          is_not,
          nil
        )
      )
    when Playwright::Locator
      Playwright::LocatorAssertions.new(
        Playwright::LocatorAssertionsImpl.new(
          actual,
          @timeout_settings.timeout,
          is_not,
          nil
        )
      )
    when Capybara::Node::Element
      actual = make_locator(element_locator_tag(actual))
      Playwright::LocatorAssertions.new(
        Playwright::LocatorAssertionsImpl.new(
          actual,
          @timeout_settings.timeout,
          is_not,
          nil
        )
      )
    when Capybara::Session
      locator = actual.send(:scopes).filter(&:present?).map { element_locator_tag(it) }.join(' ')
      actual = locator.blank? ? make_locator('html') : make_locator(locator)

      Playwright::LocatorAssertions.new(
        Playwright::LocatorAssertionsImpl.new(
          actual,
          @timeout_settings.timeout,
          is_not,
          nil
        )
      )
    else
      raise NotImplementedError.new('Only locator assertions are currently implemented')
    end
  end

  def element_locator_tag(element)
    element.instance_variable_get(:@query).instance_variable_get(:@locator)
  end

  def make_locator(locator)
    page = Capybara.current_session.driver.instance_variable_get(:@browser).instance_variable_get(:@playwright_page)

    page.locator(locator)
  end
end)
