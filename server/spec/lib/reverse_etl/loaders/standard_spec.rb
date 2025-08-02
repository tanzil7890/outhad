# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Loaders::Standard do
  describe "#write" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_name: "FacebookCustomAudience", connector_type: "destination") }
    let!(:catalog) do
      create(:catalog, connector: destination,
                       catalog: {
                         "request_rate_limit" => 60,
                         "request_rate_limit_unit" => "minute",
                         "request_rate_concurrency" => 2,
                         "streams" => [{ "name" => "batch", "batch_support" => true, "batch_size" => 10,
                                         "json_schema" => {} },
                                       { "name" => "individual", "batch_support" => false, "batch_size" => 1,
                                         "json_schema" => {} }]
                       })
    end
    let!(:sync_batch) { create(:sync, stream_name: "batch", source:, destination:) }
    let!(:sync_individual) { create(:sync, stream_name: "individual", source:, destination:) }
    let!(:sync_run_batch) { create(:sync_run, sync: sync_batch, source:, destination:, status: "queued") }
    let!(:sync_run_individual) do
      create(:sync_run, sync: sync_individual, source:, destination:, status: "queued")
    end
    let!(:sync_run_started) do
      create(:sync_run, sync: sync_individual, source:, destination:, status: "started")
    end
    let!(:sync_record_batch1) { create(:sync_record, sync: sync_batch, sync_run: sync_run_batch, primary_key: "key1") }
    let!(:sync_record_batch2) { create(:sync_record, sync: sync_batch, sync_run: sync_run_batch, primary_key: "key2") }
    let!(:sync_record_individual) { create(:sync_record, sync: sync_individual, sync_run: sync_run_individual) }
    let(:activity) { instance_double("LoaderActivity") }
    let(:connector_spec) do
      Outhad::Integrations::Protocol::ConnectorSpecification.new(
        connector_query_type: "raw_sql",
        stream_type: "dynamic",
        connection_specification: {
          :$schema => "http://json-schema.org/draft-07/schema#",
          :title => "Snowflake",
          :type => "object",
          :stream => {}
        }
      )
    end

    let!(:sync_update) { create(:sync, stream_name: "individual", source:, destination:) }
    let!(:sync_run_dest_update) do
      create(:sync_run, sync: sync_update, source:, destination:, status: "queued")
    end
    let!(:sync_record_update) do
      create(:sync_record, sync: sync_update, sync_run: sync_run_dest_update, action: "destination_update")
    end
    before do
      allow(activity).to receive(:heartbeat).and_return(activity)
      allow(activity).to receive(:cancel_requested).and_return(false)
    end
    context "when batch support is enabled" do
      tracker = Outhad::Integrations::Protocol::TrackingMessage.new(
        success: 2,
        failed: 0
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:outhad_message) { tracker.to_outhad_message }
      let(:client) { instance_double(sync_batch.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "calls process_batch_records method" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, transform).and_return(outhad_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_batch)
        expect(sync_run_batch).to have_state(:queued)
        subject.write(sync_run_batch.id, activity)
        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:in_progress)
        expect(sync_run_batch.sync_records.count).to eq(2)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("success")
        end
      end
    end

    context "when batch support is enabled and all failed" do
      tracker = Outhad::Integrations::Protocol::TrackingMessage.new(
        success: 0,
        failed: 2
      )

      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:outhad_message) { tracker.to_outhad_message }
      let(:client) { instance_double(sync_batch.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "calls process_batch_records method" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, transform).and_return(outhad_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_batch)
        subject.write(sync_run_batch.id, activity)
        expect(sync_run_batch).to have_state(:queued)
        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:in_progress)
        expect(sync_run_batch.sync_records.count).to eq(2)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end
    end

    context "when batch support is disabled" do
      tracker = Outhad::Integrations::Protocol::TrackingMessage.new(
        success: 1,
        failed: 0,
        logs: [
          Outhad::Integrations::Protocol::LogMessage.new(
            name: self.class.name,
            level: "info",
            message: { request: "Sample req", response: "Sample req", level: "info" }.to_json
          )
        ]
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:outhad_message) { tracker.to_outhad_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "calls process_individual_records method" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_return(outhad_message)
        expect(subject).to receive(:update_sync_record_logs_and_status)
          .once.with(outhad_message, sync_run_individual.sync_records.first)
          .and_call_original
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:in_progress)
        expect(sync_run_individual.sync_records.count).to eq(1)
        sync_run_individual.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("success")
        end
      end
    end
    context "when batch support is disabled and failed" do
      tracker = Outhad::Integrations::Protocol::TrackingMessage.new(
        success: 0,
        failed: 1
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:outhad_message) { tracker.to_outhad_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
        allow(activity).to receive(:heartbeat).and_return(activity)
      end

      it "calls process_individual_records throw standard error" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_raise(StandardError.new("write error"))
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
      end

      it "calls process_individual_records method" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_return(outhad_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:in_progress)
        expect(sync_run_individual.sync_records.count).to eq(1)
        sync_run_individual.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end

      it "calls process_individual_records method for destination update" do
        sync_config = sync_update.to_protocol
        sync_config.sync_run_id = sync_run_dest_update.id.to_s

        allow(sync_update.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_update").and_return(outhad_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_dest_update)
        expect(sync_run_dest_update).to have_state(:queued)
        subject.write(sync_run_dest_update.id, activity)
        sync_run_dest_update.reload
        expect(sync_run_dest_update).to have_state(:in_progress)
        expect(sync_run_dest_update.sync_records.count).to eq(1)
        sync_run_dest_update.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end

      it "request concurrency" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform]).and_return(outhad_message)
        expect(Parallel).to receive(:each).with(anything, in_threads: catalog.catalog["request_rate_concurrency"]).once
        subject.write(sync_run_individual.id, activity)
      end

      it "handles heartbeat timeout and updates sync run state" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s
        allow(activity).to receive(:cancel_requested).and_return(true)
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform]).and_return(outhad_message)
        expect(Parallel).to receive(:each).with(anything, in_threads: catalog.catalog["request_rate_concurrency"]).once
        expect { subject.write(sync_run_individual.id, activity) }
          .to raise_error(StandardError, "Cancel activity request received")
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:failed)
      end
    end

    context "when skip loading when status is corrupted" do
      tracker = Outhad::Integrations::Protocol::TrackingMessage.new(
        success: 0,
        failed: 1
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:outhad_message) { tracker.to_outhad_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "sync run started to in_progress" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_started.id.to_s
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform]).and_return(outhad_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_started).to have_state(:started)
        subject.write(sync_run_started.id, activity)
        sync_run_started.reload
        expect(sync_run_started).to have_state(:started)
      end
    end

    context "Full Refresh: Clearing Records Failure for Sync processing individual" do
      control = Outhad::Integrations::Protocol::ControlMessage.new(
        type: "full_refresh",
        emitted_at: Time.zone.now.to_i,
        status: Outhad::Integrations::Protocol::ConnectionStatusType["failed"],
        meta: { detail: "failed" }
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:outhad_message) { control.to_outhad_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "sync run started to in_progress" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_return(outhad_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_individual).to have_state(:queued)
        expect do
          subject.write(sync_run_individual.id, activity)
        end.to raise_error(Activities::LoaderActivity::FullRefreshFailed)

        sync_run_individual.reload

        expect(sync_run_individual).to have_state(:failed)
      end
    end

    context "Full Refresh: Clearing Records Failure for Sync processing for batch" do
      control = Outhad::Integrations::Protocol::ControlMessage.new(
        type: "full_refresh",
        emitted_at: Time.zone.now.to_i,
        status: Outhad::Integrations::Protocol::ConnectionStatusType["failed"],
        meta: { detail: "failed" }
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:outhad_message) { control.to_outhad_message }
      let(:client) { instance_double(sync_batch.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "calls process_batch_records method" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, transform).and_return(outhad_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_batch).to have_state(:queued)
        expect do
          subject.write(sync_run_batch.id, activity)
        end.to raise_error(Activities::LoaderActivity::FullRefreshFailed)

        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:failed)
      end
    end

    context "when the report has tracking logs with a message" do
      let(:log_message) { '{"request":"Sample log message"}' }
      let(:report) do
        double("Report", tracking: double("Tracking", logs: [double("Log", message: log_message)]))
      end

      it "returns the log message" do
        expected_result = { "request" => "Sample log message" }
        expect(subject.send(:get_sync_records_logs, report)).to eq(expected_result)
      end
    end

    context "when the report has tracking logs without a message" do
      let(:report) do
        double("Report", tracking: double("Tracking", logs: [double("Log", message: nil)]))
      end

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end

    context "when the report has tracking logs but no logs present" do
      let(:report) do
        double("Report", tracking: double("Tracking", logs: []))
      end

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end

    context "when the report does not respond to logs" do
      let(:report) { double("Report", tracking: double("Tracking")) }

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end

    context "when the report has no tracking" do
      let(:report) do
        double("Report", tracking: double("Tracking", logs: nil))
      end

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end
  end
end
