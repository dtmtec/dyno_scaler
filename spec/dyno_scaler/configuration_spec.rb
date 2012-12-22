require "spec_helper"

describe DynoScaler::Configuration do
  subject(:config) { described_class.new }

  it "defaults max_workers to 1" do
    config.max_workers.should eq(1)
  end

  it "defaults min_workers to 0" do
    config.min_workers.should eq(0)
  end

  it "defaults to not enabled" do
    config.enabled.should be_false
  end

  it "defaults job_worker_ratio to { 1 => 1, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }" do
    config.job_worker_ratio.should eq({
      1 => 1,
      2 => 25,
      3 => 50,
      4 => 75,
      5 => 100
    })
  end

  it "defaults application to nil" do
    config.application.should be_nil
  end

  context "when HEROKU_API_KEY environment variable is configured" do
    before { ENV['HEROKU_API_KEY'] = 'some-api-key' }
    after  { ENV['HEROKU_API_KEY'] = nil }

    it "defaults to enabled" do
      config.should be_enabled
    end
  end

  context "when HEROKU_APP environment variable is configured" do
    before { ENV['HEROKU_APP'] = 'my-app-on-heroku' }
    after  { ENV['HEROKU_APP'] = nil }

    it "defaults application to the value of HEROKU_APP" do
      config.application.should eq(ENV['HEROKU_APP'])
    end
  end

  describe "async" do
    it "defaults to false" do
      config.async.should be_false
    end

    context "when set to true" do
      before { config.async = true }

      it "configures a GirlFriday-callable" do
        config.async.should respond_to(:call)
      end
    end

    context "when configured with a block" do
      before do
        config.async { :ok }
      end

      it "configures the callable" do
        config.async.call.should eq(:ok)
      end
    end
  end
end
