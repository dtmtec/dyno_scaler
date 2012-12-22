# encoding: utf-8

module DynoScaler
  class Manager
    attr_accessor :current_pending_jobs

    def scale_up(current_workers, current_pending_jobs)
      return unless config.enabled?

      self.current_pending_jobs = current_pending_jobs

      heroku.scale_workers(number_of_workers_needed) if scale_up?(current_workers)
    end

    def scale_up?(current_workers)
      current_pending_jobs > 0 && number_of_workers_needed > current_workers
    end

    def scale_down(current_workers, current_pending_jobs, current_running_jobs)
      return unless config.enabled?

      self.current_pending_jobs = current_pending_jobs

      heroku.scale_workers(0) if scale_down?(current_workers, current_pending_jobs, current_running_jobs)
    end

    def scale_down?(current_workers, current_pending_jobs, current_running_jobs)
      current_workers > 0 && current_pending_jobs == 0 && current_running_jobs == 0
    end

    protected
      def config
        DynoScaler.configuration
      end

      def number_of_workers_needed
        value = config.job_worker_ratio.reverse_each.find do |_, pending_jobs|
          current_pending_jobs >= pending_jobs
        end

        value ? value.first : 0
      end

      def heroku
        @heroku ||= DynoScaler::Heroku.new config.application
      end
  end
end
