# encoding: utf-8

module DynoScaler
  class Heroku
    attr_accessor :application

    def initialize(application)
      self.application = application
    end

    def scale_workers(quantity)
      heroku_client.post_ps_scale(application, 'worker', quantity)
    end

    protected
      def heroku_client
        @heroku_client ||= ::Heroku::API.new
      end
  end
end