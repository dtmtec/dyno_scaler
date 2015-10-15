require "spec_helper"

require 'sidekiq'

describe DynoScaler::Workers::Sidekiq do
  let(:manager) { double(DynoScaler::Manager, scale_up: false, scale_down: false) }

  let(:workers) { 0 }
  let(:working) { 0 }
  let(:pending) { 1 }

  let(:stats) { double('Stats', processes_size: workers, enqueued: pending, workers_size: working) }
  let(:info)  { { workers: workers, pending: pending, working: working } }

  before do
    allow(::Sidekiq::Stats).to receive(:new).and_return(stats)
    allow(DynoScaler::Manager).to receive(:new).and_return(manager)

    ::Sidekiq.redis { |redis| redis.del 'dyno-scale-scale-down-cancelled' }
  end

  after { DynoScaler.configuration.async = false }

  describe ".info" do
    it 'returns the sidekiq stats' do
      expect(DynoScaler::Workers::Sidekiq.info).to eq(info)
    end
  end

  describe "ServerMiddleware" do
    let(:middleware) { DynoScaler::Workers::Sidekiq::ServerMiddleware.new }

    before { allow(Thread).to receive(:new).and_yield }
    before { allow(Kernel).to receive(:sleep) }

    it "yields control" do
      expect { |block| middleware.call('worker', 'msg', 'queue', &block) }.to yield_control
    end

    context "when scale down has not been cancelled" do
      it "scales down passing stats info" do
        expect(manager).to receive(:scale_down).with(info)
        middleware.call('worker', 'msg', 'queue') {}
      end
    end

    context "when scale down has been cancelled" do
      before do
        middleware.cancel_scale_down
      end

      it "does not scales down" do
        expect(manager).to_not receive(:scale_down).with(info)
        middleware.call('worker', 'msg', 'queue') {}
      end
    end
  end

  describe "ClientMiddleware" do
    let(:middleware) { DynoScaler::Workers::Sidekiq::ClientMiddleware.new }

    it "yields control" do
      expect { |block| middleware.call('worker', 'msg', 'queue', &block) }.to yield_control
    end

    it "cancels scale down" do
      expect(middleware).to receive(:cancel_scale_down)
      middleware.call('worker', 'msg', 'queue') {}
    end

    it "scales up passing info with pending increased by 1" do
      expected_info = info.merge(pending: info[:pending] + 1)
      expect(manager).to receive(:scale_up).with(expected_info)
      middleware.call('worker', 'msg', 'queue') {}
    end

    context "and async is configured" do
      let(:config) { DynoScaler.configuration }
      let(:expected_info) { info.merge(pending: info[:pending] + 1, action: :scale_up) }

      context "with default processor" do
        before { config.async = true }

        it "calls the given async processor passing the current info and the scale up action" do
          expect(config.async).to receive(:call).with(expected_info)
          middleware.call('worker', 'msg', 'queue') {}
        end

        context "and the Girl-Friday job is run" do
          before { GirlFriday::Queue.immediate! }

          after do
            GirlFriday::Queue.queue!
            DynoScaler.reset!
          end

          it "runs the scale up with the info and the scale up action" do
            expect(DynoScaler.manager).to receive(:scale_with).with(expected_info)
            middleware.call('worker', 'msg', 'queue') {}
          end
        end
      end

      context "with a block" do
        before do
          config.async { |options| :ok }
        end

        it "calls the given async processor passing the current Resque info and the scale up action" do
          expect(config.async).to receive(:call).with(expected_info)
          middleware.call('worker', 'msg', 'queue') {}
        end
      end
    end
  end
end
