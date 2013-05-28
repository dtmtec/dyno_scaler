# encoding: utf-8

module DynoScaler
  class Manager
    attr_accessor :options

    def scale_up(options)
      return unless config.enabled?

      self.options = options

      scale_to(number_of_workers_needed) if scale_up?
    end

    def scale_up?
      workers_needed = number_of_workers_needed

      pending_jobs? && workers_needed > options[:workers] && workers_needed <= config.max_workers
    end

    def scale_down(options)
      return unless config.enabled?

      self.options = options

      scale_to(config.min_workers) if scale_down?
    end

    def scale_down?
      options[:workers] > config.min_workers && !pending_jobs? && !working_jobs?
    end

    def scale_with(options)
      return unless config.enabled?

      action = options[:action] || action_for(options)
      send(action, options) if action
    end

    def running_workers
      heroku.running_workers
    end

    protected
      def config
        DynoScaler.configuration
      end

      def scale_to(number_of_workers)
        config.logger.info "Scaling workers to #{number_of_workers}"
        heroku.scale_workers(number_of_workers)
      end

      def pending_jobs?
        options[:pending] > 0
      end

      def working_jobs?
        options[:working] > 0
      end

      def number_of_workers_needed
        value = config.job_worker_ratio.reverse_each.find do |_, pending_jobs|
          options[:pending] >= pending_jobs
        end

        value ? value.first : 0
      end

      def action_for(options)
        self.options = options

        return :scale_down if scale_down?
        return :scale_up if scale_up?
      end

      def heroku
        @heroku ||= DynoScaler::Heroku.new config.application
      end
  end
end
