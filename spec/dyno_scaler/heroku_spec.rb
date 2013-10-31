require "spec_helper"

describe DynoScaler::Heroku do
  let(:application) { 'my-application-on-heroku' }
  let(:options) { nil }
  subject(:heroku_client) { DynoScaler::Heroku.new application, options }

  describe "scaling workers" do
    let(:heroku_api) { double(::Heroku::API, :post_ps_scale => false) }

    before do
      ::Heroku::API.stub(:new).and_return(heroku_api)
    end

    let(:quantity) { 2 }

    it "scales workers of the application to the given number of workers" do
      heroku_api.should_receive(:post_ps_scale).with(application, 'worker', quantity)
      heroku_client.scale_workers(quantity)
    end
  end

  describe "getting number of running workers" do
    let(:options) { { mock: true } } # Mock Excon http requests

    before { Excon.stub({method: :get}, {body: body, status: 200}) }

    context "when there are running workers" do
      let(:body) do
        [{"process"=>"web.1"}, {"process"=>"worker.1"}, {"process"=>"worker.2"}]
      end

      its(:running_workers) { should eq(2) }
    end

    context "when there are no running workers" do
      let(:body) { [{"process"=>"web.1"}] }

      its(:running_workers) { should be_zero }
    end
  end
end

