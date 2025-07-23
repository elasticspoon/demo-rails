class TestJobTwoJob < ApplicationJob
  queue_as :default

  def perform
    puts "tried"
    raise "woops"
  end
end
