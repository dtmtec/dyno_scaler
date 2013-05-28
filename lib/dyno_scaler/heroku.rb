# encoding: utf-8

module DynoScaler
  class Heroku
    attr_accessor :application, :options

    def initialize(application, options={})
      self.application = application
      self.options     = options || {}
    end

    def scale_workers(quantity)
      heroku_client.post_ps_scale(application, 'worker', quantity)
    end

    def running_workers
      heroku_client.get_ps(application).body.select do |process|
        process['process'].start_with?('worker')
      end.count
    end

    protected
      def heroku_client
        @heroku_client ||= ::Heroku::API.new(options)
      end
  end
end