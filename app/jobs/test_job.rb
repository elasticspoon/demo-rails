class TestJob < ApplicationJob
  class ConcurrencyExceededError < StandardError
    def backtrace
      [] # suppress backtrace
    end
  end

  # Custom error for when the job execution rate (throttle) is exceeded.
  ThrottleExceededError = Class.new(ConcurrencyExceededError)
  retry_on ConcurrencyExceededError, attempts: Float::INFINITY, wait: :polynomially_longer
  limits_concurrency to: 2, key: :test

  before_perform do |job|
    # Retrieve concurrency configuration for the job class.
    perform_throttle = [ 1, 30.seconds ]
    current_throttle_setting = perform_throttle

    valid_throttle = current_throttle_setting.is_a?(Array) &&
      current_throttle_setting.size == 2 &&
      current_throttle_setting[0].is_a?(Numeric) && current_throttle_setting[0] > 0 &&
      current_throttle_setting[1].is_a?(Numeric) && current_throttle_setting[1] > 0 # period (e.g., 1.minute)
    throttle_config = valid_throttle ? { count: current_throttle_setting[0].to_i, period: current_throttle_setting[1].to_i.seconds } : nil

    # Skip if no limits or throttles are configured.
    puts "throttle_config #{throttle_config.inspect}"
    next unless throttle_config

    # The concurrency key is derived from the job class name and stored by SolidQueue.
    # It should be available on the job instance via `job.concurrency_key`.
    key = job.concurrency_key
    if key.blank?
      logger.warn { "[SolidQueueConcurrency] Concurrency key is blank for #{job.class.name} (Job ID: #{job.job_id}). Skipping checks." }
      next
    end
    puts "key: #{key}"

    exceeded_reason = nil

    # Perform checks within a new, non-joinable transaction that will always be rolled back.
    # This ensures atomicity for the checks without committing any DB changes.
    ActiveRecord::Base.transaction(requires_new: true, joinable: false) do
      # Check perform_throttle: Ensures no more than X jobs are performed in Y period.
      # This check is performed only if the concurrency limit (if any) was not exceeded.
      puts "reason: #{exceeded_reason}, #{throttle_config}"
      if !exceeded_reason && throttle_config
        throttle_max_count = throttle_config[:count]
        throttle_period = throttle_config[:period]
        time_window_start = throttle_period.ago

        # Count jobs that finished successfully within the throttle period.
        # `created_at` on FinishedExecution is when it transitioned to finished state.
        # We assume this is close enough to "completion time" for throttling purposes.
        finished_in_period = SolidQueue::Job
                                .where(concurrency_key: key)
                                .where.not(finished_at: nil) # Ensure it's a successfully finished job
                                .where(finished_at: time_window_start..Time.current)
                                .count

        # # Count jobs that failed (for reasons other than throttling) within the throttle period.
        failed_in_period_not_by_throttle = SolidQueue::FailedExecution.joins(:job)
          .where(solid_queue_jobs: { concurrency_key: key })
          .where(solid_queue_failed_executions: { created_at: time_window_start..Time.current })
          .where.not("solid_queue_failed_executions.error LIKE ?", "%#{TestJob::ThrottleExceededError.name}%")
          .count

        total_completed_in_period = finished_in_period + failed_in_period_not_by_throttle
        puts "total_completed_in_period: #{total_completed_in_period}"

        # If performing the current job (+1) would exceed the throttle's max count.
        if (total_completed_in_period + 1) > throttle_max_count
          puts "Throttling"
          logger.info { "[SolidQueueConcurrency] Throttle limit of #{throttle_max_count} per #{throttle_period}s reached for key '#{key}'. Job #{job.class.name} (ID: #{job.job_id}) will be retried." }
          exceeded_reason = :throttle
        end
      end

      # Rollback the transaction as these checks are read-only.
      raise ActiveRecord::Rollback
    end # End of transaction

    # If a limit or throttle was exceeded, raise the appropriate error to trigger a retry.
    if exceeded_reason == :limit
      raise ConcurrencyExceededError, "Concurrency limit for key '#{key}' exceeded."
    elsif exceeded_reason == :throttle
      raise ThrottleExceededError, "Throttle limit for key '#{key}' exceeded."
    end
  end
  queue_as :default

  def perform
    puts "Job ran"
  end
end
