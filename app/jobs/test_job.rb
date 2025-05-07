class TestJob < ApplicationJob
  class ThrottleExceededError < StandardError
    def backtrace
      [] # suppress backtrace
    end
  end

  class_attribute :throttle_config

  def self.limits_concurrency(**kwargs)
    if kwargs[:throttle]
      self.throttle_config = kwargs[:throttle]
      kwargs.delete(:throttle)
    end

    super(**kwargs)
  end

  # Custom error for when the job execution rate (throttle) is exceeded.
  retry_on TestJob::ThrottleExceededError, attempts: Float::INFINITY, wait: :polynomially_longer
  limits_concurrency to: 2, key: :test, throttle: { limit: 1, period: 30.seconds }

  before_perform do |job|
    # Retrieve concurrency configuration for the job class.
    # Skip if no limits or throttles are configured.
    puts "throttle_config #{self.class.throttle_config.inspect}"
    next unless self.class.throttle_config

    # The concurrency key is derived from the job class name and stored by SolidQueue.
    # It should be available on the job instance via `job.concurrency_key`.
    key = job.concurrency_key
    if key.blank?
      logger.warn { "[SolidQueueConcurrency] Concurrency key is blank for #{job.class.name} (Job ID: #{job.job_id}). Skipping checks." }
      next
    end
    puts "key: #{key}"

    exceeded_reason = nil

    ActiveRecord::Base.transaction(requires_new: true, joinable: false) do
      puts "reason: #{exceeded_reason}, #{throttle_config}"
      if !exceeded_reason && self.class.throttle_config
        throttle_max_count = self.class.throttle_config[:limit]
        throttle_period = self.class.throttle_config[:period]
        time_window_start = throttle_period.ago
        puts "max: #{throttle_max_count}, period: #{throttle_period}"

        finished_in_period = SolidQueue::Job
                                .where(concurrency_key: key)
                                .where.not(finished_at: nil) # Ensure it's a successfully finished job
                                .where(finished_at: time_window_start..Time.current)
                                .count

        failed_in_period_not_by_throttle = SolidQueue::FailedExecution.joins(:job)
          .where(solid_queue_jobs: { concurrency_key: key })
          .where(solid_queue_failed_executions: { created_at: time_window_start..Time.current })
          .where.not("solid_queue_failed_executions.error LIKE ?", "%#{TestJob::ThrottleExceededError.name}%")
          .count

        total_completed_in_period = finished_in_period + failed_in_period_not_by_throttle
        puts "total_completed_in_period: #{total_completed_in_period}"

        if (total_completed_in_period + 1) > throttle_max_count
          puts "Throttling"
          logger.info { "[SolidQueueConcurrency] Throttle limit of #{throttle_max_count} per #{throttle_period}s reached for key '#{key}'. Job #{job.class.name} (ID: #{job.job_id}) will be retried." }
          exceeded_reason = :throttle
        end
      end

      # Rollback the transaction as these checks are read-only.
      raise ActiveRecord::Rollback
    end # End of transaction

    if exceeded_reason == :throttle
      raise ThrottleExceededError, "Throttle limit for key '#{key}' exceeded."
    end
  end
  queue_as :default

  def perform
    puts "Job ran"
  end
end
