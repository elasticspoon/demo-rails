module ActiveJobConcurrency
  extend ActiveSupport::Concern

  class ThrottleExceededError < StandardError
    def backtrace
      [] # suppress backtrace
    end
  end

  included do
    class_attribute :throttle_config

    def self.limits_concurrency(**kwargs)
      if kwargs[:throttle]
        self.throttle_config = kwargs[:throttle]
        kwargs.delete(:throttle)
      end

      super(**kwargs)
    end

    # Custom error for when the job execution rate (throttle) is exceeded.
    retry_on ActiveJobConcurrency::ThrottleExceededError, attempts: Float::INFINITY, wait: :polynomially_longer

    before_perform do |job|
      # Don't attempt to enforce concurrency limits with other queue adapters.
      next unless job.class.queue_adapter.is_a?(ActiveJob::QueueAdapters::SolidQueueAdapter)

      next unless self.class.throttle_config

      key = job.concurrency_key
      exceeded_reason = nil

      # this is take from good job. I am not sure if we need the transaction.
      ActiveRecord::Base.transaction(requires_new: true, joinable: false) do
        if !exceeded_reason && self.class.throttle_config
          throttle_limit = self.class.throttle_config[:limit]
          throttle_period = self.class.throttle_config[:period]
          time_window_start = throttle_period.ago

          query = SolidQueue::FailedExecution.joins(:job)
                                             .where(solid_queue_jobs: { concurrency_key: key })
                                             .where(solid_queue_jobs: { created_at: time_window_start.. })

          allowed_active_job_ids = query.where(error: nil)
                                        .or(query.where.not('solid_queue_failed_executions.error LIKE ?',
                                                            "%#{ThrottleExceededError.name}%"))
                                        .order(created_at: :asc).limit(throttle_limit).pluck(:job_id)

          unless allowed_active_job_ids.include?(job.job_id)
            logger.info do
              "[SolidQueueConcurrency] Throttle limit of #{throttle_limit} per #{throttle_period}s reached for key '#{key}'. Job #{job.class.name} (ID: #{job.job_id}) will be retried."
            end
            exceeded_reason = :throttle
            next
          end

        end

        # Rollback the transaction as these checks are read-only.
        raise ActiveRecord::Rollback
      end

      raise ThrottleExceededError, "Throttle limit for key '#{key}' exceeded." if exceeded_reason == :throttle
    end
  end
end
