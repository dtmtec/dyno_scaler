require "spec_helper"

describe DynoScaler::Heroku do
  let(:application) { 'my-application-on-heroku' }
  let(:options) { nil }
  subject(:heroku_client) { DynoScaler::Heroku.new application, options }

  describe "scaling workers" do
    let(:formation)  { double('formation') }
    let(:heroku_api) { double(PlatformAPI, formation: formation) }

    before do
      ENV['HEROKU_OAUTH_TOKEN'] = 'some-token'
      allow(PlatformAPI).to receive(:connect_oauth).with(ENV['HEROKU_OAUTH_TOKEN']).and_return(heroku_api)
    end

    after { ENV['HEROKU_OAUTH_TOKEN'] = nil }

    let(:quantity) { 2 }

    it "scales workers of the application to the given number of workers" do
      expect(heroku_api.formation).to receive(:update).with(application, 'worker', { size: quantity })
      heroku_client.scale_workers(quantity)
    end
  end
end

