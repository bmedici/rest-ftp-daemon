require "spec_helper"

describe "Swagger", feature: true do

  describe "GET #{MOUNT_SWAGGER_JSON}" do
    let!(:response) { get MOUNT_SWAGGER_JSON }

    it "responds successfully" do
      expect(response.status).to eq 200
    end

    it "exposes a JSON hash" do
      expect(JSON.parse(response.body)).to be_an_instance_of(Hash)
    end

    # it "writes the API doc" do
    #   json_file = File.expand_path "../../swagger.json"
    #   puts "YEAH: #{json_file}"
    #   File.write(json_file, response.body)
    # end

  end # GET /swagger.json

end
