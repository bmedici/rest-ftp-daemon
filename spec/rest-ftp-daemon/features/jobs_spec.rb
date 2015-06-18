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

      it "exposes the new job id" do
        response = JSON.parse post("/jobs", json: params)
        expect(response['id']).not_to be_nil
      end

      it "assigns a 'queued' status" do
        response = JSON.parse post("/jobs", json: params)
        expect(response['status']).to eq "queued"
      end

      it "creates a new job" do
        expect {
          post("/jobs", json: params)
        }.to change { jobs_list.size }.by(1)
      end
    end
  end # POST /jobs

  describe "GET /jobs/:id" do
    let(:creation_response) do
      JSON.parse post("/jobs", json: {source: "/tmp/foo", target: "/tmp/bar"}).body
    end

    let(:job_id) { creation_response.fetch('id') }

    it "is properly exposed" do
      expect(
        get("/jobs/#{job_id}").status
      ).to eq 200
    end
  end # GET /jobs/:id

end
