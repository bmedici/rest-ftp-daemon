require "spec_helper"

describe "Debug", feature: true do

  let!(:response) { get MOUNT_DEBUG }

  describe "GET #{MOUNT_DEBUG}" do

    it "responds successfully" do
      expect(response.status).to eq 200
    end

  end # GET /

end
