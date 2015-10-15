require "spec_helper"

describe DynoScaler::Configuration do
  subject(:config) { described_class.new }

  it "defaults max_workers to 1" do
    expect(config.max_workers).to eq(1)
  end

  it "defaults min_workers to 0" do
    expect(config.min_workers).to eq(0)
  end

  it "defaults to not enabled" do
    expect(config.enabled).to be_falsy
  end

  it "defaults job_worker_ratio to { 1 => 1, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }" do
    expect(config.job_worker_ratio).to eq({
      1 => 1,
      2 => 25,
      3 => 50,
      4 => 75,
      5 => 100
    })
  end

  it "defaults application to nil" do
    expect(config.application).to be_nil
  end

  context "when HEROKU_API_KEY environment variable is configured" do
    before { ENV['HEROKU_API_KEY'] = 'some-api-key' }
    after  { ENV['HEROKU_API_KEY'] = nil }

    it "defaults to enabled" do
      expect(config).to be_enabled
    end
  end

  context "when HEROKU_APP environment variable is configured" do
    before { ENV['HEROKU_APP'] = 'my-app-on-heroku' }
    after  { ENV['HEROKU_APP'] = nil }

    it "defaults application to the value of HEROKU_APP" do
      expect(config.application).to eq(ENV['HEROKU_APP'])
    end
  end

  describe "async" do
    it "defaults to false" do
      expect(config.async).to be_falsy
    end

    context "when set to true" do
      before { config.async = true }

      it "configures a GirlFriday-callable" do
        expect(config.async).to respond_to(:call)
      end
    end

    context "when configured with a block" do
      before do
        config.async { :ok }
      end

      it "configures the callable" do
        expect(config.async.call).to eq(:ok)
      end
    end
  end
end
