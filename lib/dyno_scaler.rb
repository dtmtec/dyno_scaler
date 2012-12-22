# encoding: utf-8

require "dyno_scaler/version"
require "active_support/core_ext/class/attribute"
require "heroku-api"

module DynoScaler
  autoload :Configuration, 'dyno_scaler/configuration'
  autoload :Heroku,        'dyno_scaler/heroku'
  autoload :Manager,       'dyno_scaler/manager'
  autoload :Workers,       'dyno_scaler/workers'

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.manager
    @manager ||= Manager.new
  end
end

require "dyno_scaler/engine" if defined?(Rails)
