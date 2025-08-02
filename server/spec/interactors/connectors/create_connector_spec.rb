# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::CreateConnector do
  let(:workspace) { create(:workspace) }

  context "with valid params" do
    let(:connector) { build(:connector, workspace:) }

    it "creates a connector" do
      result = described_class.call(
        workspace:,
        connector_params: connector.attributes.except("id")
      )

      expect(result.success?).to eq(true)
      expect(result.connector.persisted?).to eql(true)
      expect(result.connector.workspace_id).to eql(workspace.id)
    end
  end

  context "with invalid params" do
    let(:connector_params) do
      { workspace_id: nil,
        connector_type: "destination",
        connector_name: "klaviyo",
        configuration: nil,
        name: nil }
    end

    it "fails to create a connector" do
      result = described_class.call(workspace:, connector_params:)
      expect(result.failure?).to eq(true)
    end
  end

  context "Source connectors has different names" do
    let(:connector1) do
      create(
        :connector,
        workspace:,
        connector_type: "source",
        configuration: {
          "url" => "test",
          "username" => "user",
          "password" => "password",
          "database" => "default"
        },
        connector_name: "clickhouse",
        name: "Clickhouse 1"
      )
    end

    let(:connector2) do
      build(
        :connector,
        workspace:,
        connector_type: "source",
        configuration: {
          "url" => "test",
          "username" => "user",
          "password" => "password",
          "database" => "default"
        },
        connector_name: "clickhouse",
        name: "Clickhouse 2"
      )
    end

    it "creates the connector" do
      described_class.call(
        workspace:,
        connector_params: connector1.attributes.except("id")
      )

      result = described_class.call(
        workspace:,
        connector_params: connector2.attributes.except("id")
      )

      expect(result.success?).to eq(true)
      expect(result.connector.persisted?).to eql(true)
      expect(result.connector.workspace_id).to eql(workspace.id)
    end

    it "fails to create the connector due to same name error" do
      described_class.call(
        workspace:,
        connector_params: connector1.attributes.except("id")
      )

      result = described_class.call(
        workspace:,
        connector_params: connector1.attributes.except("id")
      )

      expect(result.failure?).to eq(true)
      expect(result.error).to eq("A connector with the same name already exists.")
    end
  end
end
