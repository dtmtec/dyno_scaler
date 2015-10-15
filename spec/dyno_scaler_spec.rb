require "spec_helper"

describe DynoScaler do
  it "returns a new configuration" do
    expect(DynoScaler.configuration).to be_a(DynoScaler::Configuration)
  end

  it "returns a new manager" do
    expect(DynoScaler.manager).to be_a(DynoScaler::Manager)
  end
end
