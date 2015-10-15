# encoding: utf-8

module DynoScaler
  module Workers
    autoload :Resque,  'dyno_scaler/workers/resque'
    autoload :Sidekiq, 'dyno_scaler/workers/sidekiq'
  end
end
