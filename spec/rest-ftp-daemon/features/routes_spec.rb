require "spec_helper"

describe 'Routes', feature: true do

  let!(:response) { get "/routes" }

  describe "GET /routes" do

    it "responds successfully" do
      expect(response.status).to eq 200
    end

    it "exposes properly formed JSON" do
      expect { JSON.parse(response.to_s) }.not_to raise_error
      expect(JSON.parse(response.to_s)).to all(have_key("options"))
    end

  end # GET /

end
