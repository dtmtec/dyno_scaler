# encoding: utf-8

module DynoScaler
  class Heroku
    attr_accessor :application, :options

    def initialize(application, options={})
      self.application = application
      self.options     = options || {}
    end

    def scale_workers(quantity)
      heroku_client.formation.update(application, 'worker', { size: quantity })
    end

    protected
      def heroku_client
        @heroku_client ||= PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
      end
  end
end
