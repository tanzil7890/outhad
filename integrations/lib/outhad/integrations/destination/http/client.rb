# frozen_string_literal: true

module Outhad
  module Integrations
    module Destination
      module Http
        include Outhad::Integrations::Core
        class Client < DestinationConnector
          MAX_CHUNK_SIZE = 10
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            destination_url = connection_config[:destination_url]
            headers = connection_config[:headers]
            request = Outhad::Integrations::Core::HttpClient.request(
              destination_url,
              HTTP_POST,
              payload: {},
              headers: headers
            )
            if success?(request)
              success_status
            else
              failure_status(nil)
            end
          rescue StandardError => e
            handle_exception(e, {
                               context: "HTTP:CHECK_CONNECTION:EXCEPTION",
                               type: "error"
                             })
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog_json = read_json(CATALOG_SPEC_PATH)
            catalog = build_catalog(catalog_json)
            catalog.to_outhad_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "HTTP:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, _action = "create")
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            url = connection_config[:destination_url]
            headers = connection_config[:headers]
            log_message_array = []
            write_success = 0
            write_failure = 0
            records.each_slice(MAX_CHUNK_SIZE) do |chunk|
              payload = create_payload(chunk)
              args = [sync_config.stream.request_method, url, payload]
              response = Outhad::Integrations::Core::HttpClient.request(
                url,
                sync_config.stream.request_method,
                payload: payload,
                headers: headers
              )
              if success?(response)
                write_success += chunk.size
              else
                write_failure += chunk.size
              end
              log_message_array << log_request_response("info", args, response)
            rescue StandardError => e
              handle_exception(e, {
                                 context: "HTTP:RECORD:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: sync_config.sync_id,
                                 sync_run_id: sync_config.sync_run_id
                               })
              write_failure += chunk.size
              log_message_array << log_request_response("error", args, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          rescue StandardError => e
            handle_exception(e, {
                               context: "HTTP:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
          end

          private

          def create_payload(records)
            {
              "records" => records.map do |record|
                {
                  "fields" => record
                }
              end
            }
          end

          def extract_body(response)
            response_body = response.body
            JSON.parse(response_body) if response_body
          end
        end
      end
    end
  end
end
