require "spec_helper"

describe DynoScaler do
  it "returns a new configuration" do
    DynoScaler.configuration.should be_a(DynoScaler::Configuration)
  end
end
