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
  let(:manager) { mock(DynoScaler::Manager, scale_up: false, scale_down: false) }

  let(:workers) { 0 }
  let(:working) { 0 }
  let(:pending) { 1 }

  before do
    Resque.stub!(:info).and_return({
      workers: workers,
      working: working,
      pending: pending
    })

    SampleJob.reset!
    DynoScaler::Manager.stub!(:new).and_return(manager)
  end

  def work_off(queue)
    job = Resque::Job.reserve(queue)
    job ? job.perform : fail("No jobs for queue '#{queue}'.")
  end

  describe "when enqueued" do
    it "scales up" do
      manager.should_receive(:scale_up).with(workers, pending)
      Resque.enqueue(SampleJob)
    end

    context "when there are workers" do
      let(:workers) { 2 }

      it "passes the number of current workers to the manager" do
        manager.should_receive(:scale_up).with(workers, pending)
        Resque.enqueue(SampleJob)
      end
    end

    context "when there are pending jobs" do
      let(:pending) { 5 }

      it "passes the number of pending jobs" do
        manager.should_receive(:scale_up).with(workers, pending)
        Resque.enqueue(SampleJob)
      end
    end

    context "when scaling up is disabled" do
      before { SampleJob.disable_scaling_up }
      after  { SampleJob.enable_scaling_up  }

      it "does not scale up" do
        manager.should_not_receive(:scale_up)
        Resque.enqueue(SampleJob)
      end
    end
  end

  describe "after performing" do
    before do
      Resque.enqueue(SampleJob)
    end

    it "scales down" do
      manager.should_receive(:scale_down).with(workers, pending, working)
      work_off(:sample)
    end

    context "when there are workers" do
      let(:workers) { 2 }

      it "passes the number of current workers to the manager" do
        manager.should_receive(:scale_down).with(workers, pending, working)
        work_off(:sample)
      end
    end

    context "when there are pending jobs" do
      let(:pending) { 5 }

      it "passes the number of pending jobs" do
        manager.should_receive(:scale_down).with(workers, pending, working)
        work_off(:sample)
      end
    end

    context "when there are running jobs" do
      let(:working) { 5 }

      it "passes the number of running jobs minus 1, since we do not count ourselves" do
        manager.should_receive(:scale_down).with(workers, pending, working - 1)
        work_off(:sample)
      end
    end

    context "when scaling down is disabled" do
      before { SampleJob.disable_scaling_down }
      after  { SampleJob.enable_scaling_down  }

      it "does not scale down" do
        manager.should_not_receive(:scale_down)
        work_off(:sample)
      end
    end
  end
end
