require "spec_helper"

require 'resque'

class SampleJob
  include DynoScaler::Workers::Resque

  @queue = :sample

  def self.perform
    # do something
  end

  def self.reset!
    @manager = nil
  end
end

describe DynoScaler::Workers::Resque do
  let(:manager) { double(DynoScaler::Manager, scale_up: false, scale_down: false) }

  let(:workers) { 0 }
  let(:working) { 0 }
  let(:pending) { 1 }

  before do
    allow(Resque).to receive(:info).and_return({
      workers: workers,
      working: working,
      pending: pending
    })

    SampleJob.reset!
    allow(DynoScaler::Manager).to receive(:new).and_return(manager)
  end

  after { DynoScaler.configuration.async = false }

  def work_off(queue)
    job = Resque::Job.reserve(queue)
    job ? job.perform : fail("No jobs for queue '#{queue}'.")
  end

  describe "when enqueued" do
    it "scales up" do
      expect(manager).to receive(:scale_up).with(Resque.info)
      Resque.enqueue(SampleJob)
    end

    context "when there are workers" do
      let(:workers) { 2 }

      it "passes the number of current workers to the manager" do
        expect(manager).to receive(:scale_up).with(Resque.info)
        Resque.enqueue(SampleJob)
      end
    end

    context "when there are pending jobs" do
      let(:pending) { 5 }

      it "passes the number of pending jobs" do
        expect(manager).to receive(:scale_up).with(Resque.info)
        Resque.enqueue(SampleJob)
      end
    end

    context "when it is scaling" do
      before { allow(SampleJob).to receive(:scaling?).and_return(true) }

      it "does not scales up" do
        expect(manager).to_not receive(:scale_up)
        Resque.enqueue(SampleJob)
      end

      context "and async is configured" do
        let(:config) { DynoScaler.configuration }
        before { config.async = true }

        it "does not calls the given async processor" do
          expect(config.async).to_not receive(:call)
          Resque.enqueue(SampleJob)
        end
      end
    end

    context "when scaling up is disabled" do
      before { SampleJob.disable_scaling_up }
      after  { SampleJob.enable_scaling_up  }

      it "does not scale up" do
        expect(manager).to_not receive(:scale_up)
        Resque.enqueue(SampleJob)
      end
    end

    context "when an error occurs while scaling up" do
      before do
        allow(manager).to receive(:scale_up).and_raise("error")
      end

      it "does not raises it" do
        capture(:stderr) do
          expect { Resque.enqueue(SampleJob) }.to_not raise_error
        end
      end

      it "enqueues the job" do
        capture(:stderr) do
          Resque.enqueue(SampleJob)
          work_off(:sample)
        end
      end

      it "prints a message in $stderr" do
        expect(capture(:stderr) { Resque.enqueue(SampleJob) }).to eq("Could not scale up workers: error\n")
      end
    end

    context "and async is configured" do
      let(:config) { DynoScaler.configuration }

      context "with default processor" do
        before { config.async = true }

        it "calls the given async processor passing the current Resque info and the scale up action" do
          expect(config.async).to receive(:call).with(Resque.info.merge(action: :scale_up))
          Resque.enqueue(SampleJob)
        end

        context "and the Girl-Friday job is run" do
          before { GirlFriday::Queue.immediate! }

          after do
            GirlFriday::Queue.queue!
            DynoScaler.reset!
          end

          it "runs the scale up with the Resque info and the scale up action" do
            expect(DynoScaler.manager).to receive(:scale_with).with(Resque.info.merge(action: :scale_up))
            Resque.enqueue(SampleJob)
          end
        end
      end

      context "with a block" do
        before do
          config.async { |options| :ok }
        end

        it "calls the given async processor passing the current Resque info and the scale up action" do
          expect(config.async).to receive(:call).with(Resque.info.merge(action: :scale_up))
          Resque.enqueue(SampleJob)
        end
      end
    end
  end

  describe "#scale" do
    it "calls the Klass.scale" do
      block = Proc.new { |a| }
      expect(SampleJob).to receive(:scale).and_yield(block)
      SampleJob.new.scale(&block)
    end
  end

  describe ".scale" do
    before { allow(manager).to receive(:scale_with) }

    it "should not be scaling before it is run" do
      expect(SampleJob).to_not be_scaling
      SampleJob.scale { }
    end

    it "should not be scaling after it is run" do
      SampleJob.scale { }
      expect(SampleJob).to_not be_scaling
    end

    it "calls the given block" do
      called = false
      SampleJob.scale do
        called = true
      end

      expect(called).to be_truthy
    end

    it "sets scaling? to true inside the given block" do
      SampleJob.scale do
        expect(SampleJob).to be_scaling
      end
    end

    it "returns the result of the block" do
      result = SampleJob.scale do
        'some value'
      end

      expect(result).to eq('some value')
    end

    it "scales with Resque.info" do
      expect(manager).to receive(:scale_with).with(Resque.info)
      SampleJob.scale {}
    end
  end

  describe "after performing" do
    before do
      Resque.enqueue(SampleJob)
    end

    it "scales down" do
      expect(manager).to receive(:scale_down).with(Resque.info)
      work_off(:sample)
    end

    context "when there are workers" do
      let(:workers) { 2 }

      it "passes the number of current workers to the manager" do
        expect(manager).to receive(:scale_down).with(Resque.info)
        work_off(:sample)
      end
    end

    context "when there are pending jobs" do
      let(:pending) { 5 }

      it "passes the number of pending jobs" do
        expect(manager).to receive(:scale_down).with(Resque.info)
        work_off(:sample)
      end
    end

    context "when there are running jobs" do
      let(:working) { 5 }

      it "passes the number of running jobs minus 1, since we do not count ourselves" do
        expect(manager).to receive(:scale_down).with(Resque.info.merge(working: Resque.info[:working] - 1))
        work_off(:sample)
      end
    end

    context "when scaling down is disabled" do
      before { SampleJob.disable_scaling_down }
      after  { SampleJob.enable_scaling_down  }

      it "does not scale down" do
        expect(manager).to_not receive(:scale_down)
        work_off(:sample)
      end
    end

    context "when an error occurs while scaling down" do
      before do
        allow(manager).to receive(:scale_down).and_raise("error")
      end

      it "does not raises it" do
        capture(:stderr) do
          expect { work_off(:sample) }.to_not raise_error
        end
      end

      it "prints a message in $stderr" do
        expect(capture(:stderr) { work_off(:sample) }).to eq("Could not scale down workers: error\n")
      end
    end
  end
end
