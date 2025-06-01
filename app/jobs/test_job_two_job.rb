class TestJobTwoJob < ApplicationJob
  queue_as :default

  # retry_on(StandardError, attempts: 5) do |job, _|
  #   puts "retrying job #{job.job_id}"
  # end
  discard_on(StandardError) do
    puts "discarded"
  end
  retry_on(StandardError, attempts: 3)
  retry_on(StandardError) do |job, _|
    puts "gave up on #{job.job_id}"
  end

  def perform
    puts "tried"
    raise "woops"
  end
end
