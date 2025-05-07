# frozen_string_literal: true

require "active_support/concern"
require "active_job"

module SolidQueueExtensions
  module Concurrency
    extend ActiveSupport::Concern

    # Custom error for when the maximum number of concurrent jobs is exceeded.
    # Suppresses backtrace for cleaner logs, as this is an expected condition.
    class ConcurrencyExceededError < StandardError
      def backtrace
        [] # suppress backtrace
      end
    end

    # Custom error for when the job execution rate (throttle) is exceeded.
    ThrottleExceededError = Class.new(ConcurrencyExceededError)

    # Prepended methods for ActiveJob serialization.
    module JobPrepends
      # Serializes the job data, adding the automatically generated concurrency key.
      # This key is stored in SolidQueue::Job.concurrency_key.
      def serialize
        super.merge("concurrency_key" => _solid_queue_generated_concurrency_key)
      end
    end

    included do
      prepend JobPrepends

      # Class attribute to store concurrency configuration (limits and throttles).
      # Defaults to an empty hash, meaning no concurrency control by default.
      class_attribute :solid_queue_concurrency_options, instance_accessor: false, default: {}

      # Determine the retry wait strategy based on ActiveJob version.
      # Rails 7.1+ uses polynomial backoff, older versions use exponential.
      wait_key = if ActiveJob.gem_version >= Gem::Version.new("7.1.0.a")
                   :polynomially_longer
      else
                   :exponentially_longer
      end

      # Configure jobs to automatically retry indefinitely if they exceed concurrency or throttle limits.
      # The wait time between retries will increase.
      retry_on ConcurrencyExceededError, attempts: Float::INFINITY, wait: wait_key

      # Callback executed before a job is performed.
      # This is where concurrency and throttle limits are checked.
      before_perform do |job|
        # Skip checks if not using SolidQueue adapter.
        unless job.class.queue_adapter.is_a?(SolidQueue::Adapter)
          logger.debug { "[SolidQueueConcurrency] Skipping checks for #{job.class.name} (Job ID: #{job.job_id}) as it's not using SolidQueueAdapter." }
          next
        end

        # Skip checks if the job is being performed synchronously via perform_now.
        # These throttles are primarily intended for background worker processing.
        if Thread.current[:active_job_performing_now]
          logger.debug { "[SolidQueueConcurrency] Skipping checks for #{job.class.name} (Job ID: #{job.job_id}) as it's running via perform_now." }
          next
        end

        # Retrieve concurrency configuration for the job class.
        options = job.class.solid_queue_concurrency_options
        perform_limit = options[:perform_limit]
        total_limit = options[:total_limit] # Fallback for perform_limit
        perform_throttle = options[:perform_throttle] # Expected format: [count, period_in_seconds]

        # Determine the actual limit to use (perform_limit or total_limit).
        limit_value = perform_limit || total_limit
        limit_value = instance_exec(&limit_value) if limit_value.respond_to?(:call)
        limit_value = nil unless limit_value.present? && (0...Float::INFINITY).cover?(limit_value.to_i)


        # Validate and prepare throttle settings.
        if perform_throttle.respond_to?(:call)
          current_throttle_setting = instance_exec(&perform_throttle)
        else
          current_throttle_setting = perform_throttle
        end

        valid_throttle = current_throttle_setting.is_a?(Array) &&
                         current_throttle_setting.size == 2 &&
                         current_throttle_setting[0].is_a?(Numeric) && current_throttle_setting[0] > 0 &&
                         current_throttle_setting[1].is_a?(Numeric) && current_throttle_setting[1] > 0 # period (e.g., 1.minute)
        throttle_config = valid_throttle ? { count: current_throttle_setting[0].to_i, period: current_throttle_setting[1].to_i.seconds } : nil

        # Skip if no limits or throttles are configured.
        next unless limit_value || throttle_config

        # The concurrency key is derived from the job class name and stored by SolidQueue.
        # It should be available on the job instance via `job.concurrency_key`.
        key = job.concurrency_key
        if key.blank?
          logger.warn { "[SolidQueueConcurrency] Concurrency key is blank for #{job.class.name} (Job ID: #{job.job_id}). Skipping checks." }
          next
        end

        exceeded_reason = nil

        # Perform checks within a new, non-joinable transaction that will always be rolled back.
        # This ensures atomicity for the checks without committing any DB changes.
        ActiveRecord::Base.transaction(requires_new: true, joinable: false) do
          # Check perform_limit: Ensures only N jobs with this key are actively running.
          if limit_value
            # Find active_job_ids of jobs currently claimed by workers for this concurrency key,
            # ordered by priority and then creation time, up to the specified limit.
            allowed_job_ids = SolidQueue::ClaimedExecution.joins(:job)
                                .where(solid_queue_jobs: { concurrency_key: key })
                                .order(Arel.sql("solid_queue_jobs.priority ASC, solid_queue_jobs.created_at ASC")) # Ensure stable order
                                .limit(limit_value)
                                .pluck(Arel.sql("solid_queue_jobs.active_job_id")) # Use Arel.sql for clarity if table name is complex

            # If the current job's ID is not in this list of allowed jobs, it means the limit is met by other jobs.
            unless allowed_job_ids.include?(job.job_id)
              logger.info { "[SolidQueueConcurrency] Concurrency limit of #{limit_value} reached for key '#{key}'. Job #{job.class.name} (ID: #{job.job_id}) will be retried." }
              exceeded_reason = :limit
            end
          end

          # Check perform_throttle: Ensures no more than X jobs are performed in Y period.
          # This check is performed only if the concurrency limit (if any) was not exceeded.
          if !exceeded_reason && throttle_config
            throttle_max_count = throttle_config[:count]
            throttle_period = throttle_config[:period]
            time_window_start = throttle_period.ago

            # Count jobs that finished successfully within the throttle period.
            # `created_at` on FinishedExecution is when it transitioned to finished state.
            # We assume this is close enough to "completion time" for throttling purposes.
            finished_in_period = SolidQueue::FinishedExecution.joins(:job)
                                   .where(solid_queue_jobs: { concurrency_key: key })
                                   .where(solid_queue_finished_executions: { created_at: time_window_start..Time.current })
                                   .count

            # Count jobs that failed (for reasons other than throttling) within the throttle period.
            failed_in_period_not_by_throttle = SolidQueue::FailedExecution.joins(:job)
                                               .where(solid_queue_jobs: { concurrency_key: key })
                                               .where(solid_queue_failed_executions: { created_at: time_window_start..Time.current })
                                               .where.not("solid_queue_failed_executions.error LIKE ?", "%#{ThrottleExceededError.name}%")
                                               .count

            total_completed_in_period = finished_in_period + failed_in_period_not_by_throttle

            # If performing the current job (+1) would exceed the throttle's max count.
            if (total_completed_in_period + 1) > throttle_max_count
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
    end # included

    class_methods do
      # Configures concurrency controls for jobs of this class.
      #
      # @param perform_limit [Integer, Proc, nil] Maximum number of jobs of this type that can be actively performing at once.
      #   A Proc can be used for dynamic limits, evaluated in the job's context.
      # @param total_limit [Integer, Proc, nil] Fallback for `perform_limit` if `perform_limit` is not set.
      # @param perform_throttle [Array<Integer, ActiveSupport::Duration>, Proc, nil] Throttling configuration, e.g., `[10, 1.minute]`.
      #   Means "allow up to 10 jobs to start performing per 1 minute period".
      #   A Proc can be used for dynamic throttle settings.
      def solid_queue_throttle_perform(perform_limit: nil, total_limit: nil, perform_throttle: nil)
        options = {}
        options[:perform_limit] = perform_limit if perform_limit
        options[:total_limit] = total_limit if total_limit
        options[:perform_throttle] = perform_throttle if perform_throttle
        self.solid_queue_concurrency_options = options
      end
    end

    private

    # Generates the concurrency key for the job instance.
    # By default, this is the job's class name.
    # This method is called during job serialization.
    # @return [String] The concurrency key.
    def _solid_queue_generated_concurrency_key
      self.class.name.to_s
    end
  end
end
