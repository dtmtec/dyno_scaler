require "spec_helper"

describe DynoScaler::Heroku do
  let(:application) { 'my-application-on-heroku' }
  subject(:heroku_client) { DynoScaler::Heroku.new application }

  let(:heroku_api) { mock(::Heroku::API, :post_ps_scale => false) }

  before do
    ::Heroku::API.stub!(:new).and_return(heroku_api)
  end

  describe "scaling workers" do
    let(:quantity) { 2 }

    it "scales workers of the application to the given number of workers" do
      heroku_api.should_receive(:post_ps_scale).with(application, 'worker', quantity)
      heroku_client.scale_workers(quantity)
    end
  end
end

