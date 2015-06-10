require "spec_helper"

describe 'Dashboard', feature: true do

  describe "GET /" do
    context 'without a password' do
      it 'is forbidden' do
        expect(HTTP.accept(:json).get("http://localhost:5678").status).to eq 401
      end
    end

    context 'with a password' do
      it 'can be accessed' do
        expect(
          HTTP.accept(:json).
            basic_auth(user: 'admin', pass: 'admin').
            get("http://localhost:5678").status
        ).to eq 200
      end
    end
  end # GET /

end
