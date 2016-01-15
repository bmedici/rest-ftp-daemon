require "spec_helper"

describe "Routes", feature: true do

  let!(:response) { get "/routes" }

  describe "GET /routes" do

    it "responds successfully" do
      expect(response.status).to eq 200
    end

  end # GET /

end
