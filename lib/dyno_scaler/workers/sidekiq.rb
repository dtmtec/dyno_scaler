module DynoScaler
  module Workers
    module Sidekiq
      module BaseMiddleware
        def dyno_scaler_manager
          @manager ||= DynoScaler::Manager.new
        end

        def info
          stats = ::Sidekiq::Stats.new

          {
            workers: stats.processes_size,
            pending: stats.enqueued,
            working: stats.workers_size
          }
        end

        def scale_down_cancelled?
          ::Sidekiq.redis { |redis| redis.exists('dyno-scale-scale-down-cancelled') }
        end

        def cancel_scale_down
          ::Sidekiq.redis { |redis| redis.set('dyno-scale-scale-down-cancelled', 'true', ex: 5) }
        end
      end
      extend BaseMiddleware

      class ServerMiddleware
        include DynoScaler::Workers::Sidekiq::BaseMiddleware

        def call(worker, msg, queue)
          yield

          Thread.new do
            Kernel.sleep 5 # account for sidekiq's heartbeat

            unless scale_down_cancelled?
              dyno_scaler_manager.scale_down(info)
            end
          end
        end
      end

      class ClientMiddleware
        include DynoScaler::Workers::Sidekiq::BaseMiddleware

        def call(worker_class, msg, queue, redis_pool=nil)
          yield.tap do
            cancel_scale_down

            data = info
            data.merge!(pending: data[:pending] + 1)

            if DynoScaler.configuration.async?
              DynoScaler.configuration.async.call(data.merge(action: :scale_up))
            else
              dyno_scaler_manager.scale_up(data)
            end
          end
        end
      end
    end
  end
end
