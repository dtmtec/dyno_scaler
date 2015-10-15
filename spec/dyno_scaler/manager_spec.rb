require "spec_helper"

describe DynoScaler::Manager do
  let(:config) { DynoScaler.configuration }

  subject(:manager) { DynoScaler::Manager.new }

  let(:heroku) { double(DynoScaler::Heroku, scale_workers: false) }

  let(:workers)      { 0 }
  let(:pending_jobs) { 0 }
  let(:running_jobs) { 0 }

  let(:options) do
    {
      workers: workers,
      pending: pending_jobs,
      working: running_jobs
    }
  end

  before do
    DynoScaler.reset!
    DynoScaler.configuration.logger = Logger.new(StringIO.new)

    config.max_workers = 5
    config.application = 'my-app'
    config.enabled = true

    config.redis.del "dyno-scaler-throttle"

    allow(DynoScaler::Heroku).to receive(:new).with(config.application).and_return(heroku)
  end

  shared_examples_for "disabled" do
    before { config.enabled = false }

    it "does nothing" do
      expect(heroku).to_not receive(:scale_workers)
      perform_action
    end
  end

  shared_examples_for "throttling" do
    context "when there is a throttle key" do
      let(:throttle_value) { 0 }
      before { config.redis.set("dyno-scaler-throttle", throttle_value) }

      context "with a value that is smaller than the number_of_workers" do
        let(:throttle_value) { number_of_workers - 1 }

        it "will scale workers" do
          expect(heroku).to receive(:scale_workers).with(number_of_workers)
          perform_action
        end
      end

      context "with a value that is equal to the number_of_workers" do
        let(:throttle_value) { number_of_workers }

        it "will not scale workers" do
          expect(heroku).to_not receive(:scale_workers)
          perform_action
        end
      end

      context "with a value that is greater than the number_of_workers" do
        let(:throttle_value) { number_of_workers + 1 }

        it "will scale workers" do
          expect(heroku).to receive(:scale_workers).with(number_of_workers)
          perform_action
        end
      end
    end
  end

  describe "scale up" do
    def perform_action
      manager.scale_up(options)
    end

    context "when there are no workers running" do
      context "and there is no pending jobs" do
        it "does nothing" do
          expect(heroku).to_not receive(:scale_workers)
          perform_action
        end
      end

      DynoScaler.configuration.job_worker_ratio.keys.each do |number_of_workers|
        context "and there is enough pending jobs so as to scale #{number_of_workers} workers" do
          let(:pending_jobs) { config.job_worker_ratio[number_of_workers] }

          it "scales workers to #{number_of_workers}" do
            expect(heroku).to receive(:scale_workers).with(number_of_workers)
            perform_action
          end

          it_should_behave_like "disabled"
          it_should_behave_like "throttling" do
            let(:number_of_workers) { number_of_workers }
          end
        end
      end
    end

    context "when there is one worker running" do
      let(:workers) { 1 }

      context "and there is no pending jobs" do
        it "does nothing" do
          expect(heroku).to_not receive(:scale_workers)
          perform_action
        end
      end

      context "and there is less pending jobs that would require another worker" do
        let(:pending_jobs) { config.job_worker_ratio[2] - 1 }

        it "does nothing" do
          expect(heroku).to_not receive(:scale_workers)
          perform_action
        end
      end

      context "and there is enough pending jobs as to scale another worker" do
        let(:pending_jobs) { config.job_worker_ratio[2] }

        it "scales workers" do
          expect(heroku).to receive(:scale_workers).with(2)
          perform_action
        end

        it_should_behave_like "throttling" do
          let(:number_of_workers) { 2 }
        end
      end
    end

    context "when there are many workers running" do
      let(:workers) { 4 }

      context "and there is no pending jobs" do
        it "does nothing" do
          expect(heroku).to_not receive(:scale_workers)
          perform_action
        end
      end

      context "and there is less pending jobs that would require another worker" do
        let(:pending_jobs) { config.job_worker_ratio[4] - 1 }

        it "does nothing" do
          expect(heroku).to_not receive(:scale_workers)
          perform_action
        end
      end

      context "and there is enough pending jobs as to scale another worker" do
        let(:pending_jobs) { config.job_worker_ratio[5] }

        it "scales workers" do
          expect(heroku).to receive(:scale_workers).with(5)
          perform_action
        end

        it_should_behave_like "throttling" do
          let(:number_of_workers) { 5 }
        end
      end

      context "and it is the maximum number of workers running" do
        before { config.max_workers = workers }

        context "and there is enough pending jobs as to scale another worker" do
          let(:pending_jobs) { config.job_worker_ratio[5] }

          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end
      end
    end
  end

  describe "scale down" do
    def perform_action
      manager.scale_down(options)
    end

    context "when there are no workers running" do
      it "does nothing" do
        expect(heroku).to_not receive(:scale_workers)
        perform_action
      end
    end

    context "when there is one worker running" do
      let(:workers) { 1 }

      context "and there are no pending jobs" do
        context "and no running jobs" do
          it "scales down" do
            expect(heroku).to receive(:scale_workers).with(config.min_workers)
            perform_action
          end

          it_should_behave_like "throttling" do
            let(:number_of_workers) { config.min_workers }
          end

          context "when min_workers is configured with a different value" do
            before { config.min_workers = 1 }

            it "does nothing" do
              expect(heroku).to_not receive(:scale_workers)
              perform_action
            end
          end
        end

        context "but there are many running jobs" do
          let(:running_jobs) { 4 }

          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end
      end

      context "and there are pending jobs" do
        let(:pending_jobs) { 1 }

        context "and no running jobs" do
          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end

        context "but there are running jobs" do
          let(:running_jobs) { 1 }

          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end
      end
    end

    context "when there are many workers running" do
      let(:workers) { 4 }

      context "and there are no pending jobs" do
        context "and no running jobs" do
          it "scales down" do
            expect(heroku).to receive(:scale_workers).with(config.min_workers)
            perform_action
          end

          it_should_behave_like "throttling" do
            let(:number_of_workers) { config.min_workers }
          end

          context "when min_workers is configured with a different value" do
            before { config.min_workers = 2 }

            it "scales down to the min workers value" do
              expect(heroku).to receive(:scale_workers).with(config.min_workers)
              perform_action
            end

            it_should_behave_like "throttling" do
              let(:number_of_workers) { config.min_workers }
            end
          end
        end

        context "but there are many running jobs" do
          let(:running_jobs) { 4 }

          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end
      end

      context "and there are pending jobs" do
        let(:pending_jobs) { 1 }

        context "and no running jobs" do
          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end

        context "but there are running jobs" do
          let(:running_jobs) { 1 }

          it "does nothing" do
            expect(heroku).to_not receive(:scale_workers)
            perform_action
          end
        end
      end
    end
  end

  describe "scale with options" do
    let(:action) { :scale_up }
    let(:options) do
      {
        action: action,
        workers: workers,
        pending: pending_jobs,
        working: running_jobs
      }
    end

    def perform_action
      manager.scale_with(options)
    end

    context "when action is scale up" do
      it "scales up passing options" do
        expect(manager).to receive(:scale_up).with(options)
        perform_action
      end
    end

    context "when action is scale down" do
      let(:action) { :scale_down }

      it "scales down passing options" do
        expect(manager).to receive(:scale_down).with(options)
        perform_action
      end
    end

    context "when no action is provided" do
      let(:options) do
        {
          workers: workers,
          pending: pending_jobs,
          working: running_jobs
        }
      end

      context "when there are no workers running" do
        context "and there is no pending jobs" do
          it "does nothing" do
            expect(manager).to_not receive(:scale_up)
            expect(manager).to_not receive(:scale_down)
            perform_action
          end
        end

        context "and there is pending jobs" do
          let(:pending_jobs) { 2 }

          it "scales up" do
            expect(manager).to receive(:scale_up).with(options)
            perform_action
          end
        end
      end

      context "when there are workers running" do
        let(:workers) { 4 }

        context "and there are no pending jobs" do
          context "and no running jobs" do
            it "scales down" do
              expect(manager).to receive(:scale_down).with(options)
              perform_action
            end
          end

          context "but there are many running jobs" do
            let(:running_jobs) { 4 }

            it "does nothing" do
              expect(manager).to_not receive(:scale_up)
              expect(manager).to_not receive(:scale_down)
              perform_action
            end
          end
        end

        context "and there are pending jobs" do
          let(:pending_jobs) { 1 }

          it "does nothing" do
            expect(manager).to_not receive(:scale_up)
            expect(manager).to_not receive(:scale_down)
            perform_action
          end
        end
      end
    end
  end

  describe "running workers" do
    let(:heroku) { double(DynoScaler::Heroku, scale_workers: false, running_workers: 2) }

    its(:running_workers) { should eq(heroku.running_workers) }
  end
end
