require "spec_helper"

describe DynoScaler do
  it "returns a new configuration" do
    DynoScaler.configuration.should be_a(DynoScaler::Configuration)
  end

  it "returns a new manager" do
    DynoScaler.manager.should be_a(DynoScaler::Manager)
  end
end
