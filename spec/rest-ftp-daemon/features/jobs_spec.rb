require "spec_helper"

describe "Jobs", feature: true do

  describe "GET /jobs" do
    let!(:response) { get "/jobs" }

    it "responds successfully" do
      expect(response.status).to eq 200
    end

    it "exposes an array" do
      expect(JSON.parse(response.body)).to be_an_instance_of(Array)
    end
  end # GET /jobs

  describe "POST /jobs" do
    def jobs_list
      JSON.parse get("/jobs").body
    end

    context "when params are valid" do
      let(:params) do
        {
          source: "/tmp/foo",
          target: "/tmp/bar"
        }
      end

      it "issues a 201 response" do
        expect(
          post("/jobs", json: params).status
        ).to eq 201
      end

      it "creates a new job" do
        expect {
          post("/jobs", json: params)
        }.to change { jobs_list.size }.by(1)
      end
    end

  end # POST /jobs

end
