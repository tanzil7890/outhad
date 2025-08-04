# frozen_string_literal: true

require "stringio"

module Outhad
  module Integrations
    module Destination
      module SalesforceCrm
        include Outhad::Integrations::Core

        API_VERSION = "59.0"

        class Client < DestinationConnector
          prepend Outhad::Integrations::Core::RateLimiter
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_outhad_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "SALESFORCE:CRM:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, action = "create")
            @action = sync_config.stream.action || action
            @sync_config = sync_config
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "SALESFORCE:CRM:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            @client = Restforce.new(oauth_token: config[:access_token],
                                    refresh_token: config[:refresh_token],
                                    instance_url: config[:instance_url],
                                    client_id: config[:client_id],
                                    client_secret: config[:client_secret],
                                    authentication_callback: proc { |x| log_debug(x.to_s) },
                                    api_version: API_VERSION)
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            properties = stream.json_schema[:properties]
            records.each do |record_object|
              record = extract_data(record_object, properties)
              args = [stream.name, "Id", record]
              response = send_data_to_salesforce(args)
              write_success += 1
              log_message_array << log_request_response("info", args, response)
            rescue StandardError => e
              # TODO: add sync_id and sync_run_id to the logs
              handle_exception(e, {
                                 context: "SALESFORCE:CRM:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: @sync_config.sync_id,
                                 sync_run_id: @sync_config.sync_run_id
                               })
              write_failure += 1
              log_message_array << log_request_response("error", args, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def send_data_to_salesforce(args)
            method_name = "upsert!"
            @client.send(method_name, *args)
          end

          def authenticate_client
            @client.authenticate!
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_outhad_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: error.message).to_outhad_message
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def log_debug(message)
            Outhad::Integrations::Service.logger.debug(message)
          end
        end
      end
    end
  end
end
