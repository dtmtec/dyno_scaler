# encoding: utf-8

module DynoScaler
  class Engine < ::Rails::Engine
    config.dyno_scaler = DynoScaler.configuration
  end
end
