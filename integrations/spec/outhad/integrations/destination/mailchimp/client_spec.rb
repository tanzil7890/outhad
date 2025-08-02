# frozen_string_literal: true

RSpec.describe Outhad::Integrations::Destination::Mailchimp::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:api_key) { "api_key" }
  let(:list_id) { "list_id" }
  let(:server) { api_key.split("-").last }
  let(:email_template_id) { "email_template_id" }
  let(:connection_config) do
    {
      api_key: api_key,
      list_id: list_id,
      email_template_id: email_template_id
    }
  end

  let(:mailchimp_audience_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "Audience" }.json_schema
  end

  let(:mailchimp_tags_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "Tags" }.json_schema
  end

  let(:mailchimp_capaigns_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "Campaigns" }.json_schema
  end

  let(:sync_config_json) do
    { source: {
        name: "SourceConnectorName",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Mailchimp",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM CALL_CENTER LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "Audience",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: mailchimp_audience_json_schema
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:records) do
    [
      { email: "jane@example.com",
        first_name: "Jane",
        last_name: "Doe" },
      { email: "jane@example.com",
        first_name: "Jane",
        last_name: "Doe" }
    ]
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        stub_request(:get, "https://#{server}.api.mailchimp.com/3.0/lists")
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns a successful connection status" do
        allow(client).to receive(:authenticate_client).and_return(true)

        response = client.check_connection(connection_config)

        expect(response).to be_a(Outhad::Integrations::Protocol::OuthadMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:authenticate_client).and_raise(StandardError.new("connection failed"))

        response = client.check_connection(connection_config)

        expect(response).to be_a(Outhad::Integrations::Protocol::OuthadMessage)
        expect(response.connection_status.status).to eq("failed")
        expect(response.connection_status.message).to eq("connection failed")
      end
    end
  end

  describe "#write" do
    let(:list_member_url) { "https://#{server}.api.mailchimp.com/3.0/lists/#{list_id}/members" }

    context "when the write operation is successful" do
      before do
        stub_request(:put, "#{list_member_url}/#{Digest::MD5.hexdigest(records.first[:email].downcase)}")
          .to_return(status: 200, body: '{"detail": "Success"}', headers: {})
      end

      it "increments the success count" do
        response = client.write(sync_config, records)

        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Outhad::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation fails" do
      before do
        # Mock the request to simulate a failure when trying to add/update a list member
        stub_request(:put, "#{list_member_url}/#{Digest::MD5.hexdigest(records.first[:email].downcase)}")
          .to_return(status: 400, body: '{"detail": "Invalid Request"}', headers: {})
      end

      it "increments the failure count" do
        response = client.write(sync_config, records)

        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
        log_message = response.tracking.logs.first
        expect(log_message).to be_a(Outhad::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Outhad/outhad/main/integrations/lib/outhad/integrations/destination/mailchimp/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  private

  def sync_config
    Outhad::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover
      catalog = message.catalog
      expect(catalog).to be_a(Outhad::Integrations::Protocol::Catalog)
      catalog.streams.each do |stream|
        case stream.name
        when "Audience"
          expect(stream.supported_sync_modes).to eql(["incremental"])
        when "Tags"
          expect(stream.supported_sync_modes).to eql(["incremental"])
        when "Campaigns"
          expect(stream.supported_sync_modes).to eql(["full_refresh"])
        end
      end
    end
  end
end
