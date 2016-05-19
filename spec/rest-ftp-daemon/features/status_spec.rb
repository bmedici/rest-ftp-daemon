require "spec_helper"

describe "Status", feature: true do

  let!(:response) { get MOUNT_STATUS }

  describe "GET #{MOUNT_DEBUG}" do

    it "responds successfully" do
      expect(response.status).to eq 200
    end

    it "exposes properly formed JSON" do
      expect { JSON.parse(response.to_s) }.not_to raise_error
    end

  end # GET /status

end
