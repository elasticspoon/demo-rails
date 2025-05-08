class TestJob < ApplicationJob
  include ActiveJobConcurrency

  self.queue_adapter = :solid_queue unless Rails.env.test?
  queue_as :default
  limits_concurrency to: 2, key: :test, throttle: { limit: 1, period: 30.seconds }

  def perform
    puts 'I RAN'
  end
end
