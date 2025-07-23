class TestJob < ApplicationJob
  include ActiveJobConcurrency

  self.queue_adapter = :solid_queue unless Rails.env.test?
  queue_as :default

  def perform
    raise "i failed"
  end
end
