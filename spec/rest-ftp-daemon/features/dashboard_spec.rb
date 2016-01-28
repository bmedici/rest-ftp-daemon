require "spec_helper"

describe "Dashboard", feature: true do

  describe "GET #{MOUNT_BOARD}" do
    context 'without a password' do
      it 'is forbidden' do
        expect(HTTP.accept(:json).get("http://localhost:#{RequestHelpers::PORT}").status).to eq 401
      end
    end

    context "with a password" do
      it "can be accessed" do
        expect(
            get(MOUNT_BOARD).status
        ).to eq 200
      end
    end

    it "has an HTML representation" do
      expect(
        get(MOUNT_BOARD, accept: 'html').status
      ).to eq 200
    end
  end # GET /

end
