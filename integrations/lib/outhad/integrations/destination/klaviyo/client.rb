# frozen_string_literal: true

module Outhad::Integrations::Destination
  module Klaviyo
    include Outhad::Integrations::Core
    class Client < DestinationConnector
      prepend Outhad::Integrations::Core::RateLimiter
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        api_key = connection_config[:private_api_key]

        response = Outhad::Integrations::Core::HttpClient.request(
          KLAVIYO_AUTH_ENDPOINT,
          HTTP_POST,
          payload: KLAVIYO_AUTH_PAYLOAD,
          headers: auth_headers(api_key)
        )
        parse_response(response)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)

        catalog = build_catalog(catalog_json)

        catalog.to_outhad_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "KLAVIYO:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        connection_config = connection_config.with_indifferent_access
        url = sync_config.stream.url

        request_method = sync_config.stream.request_method

        log_message_array = []
        write_success = 0
        write_failure = 0
        records.each do |record|
          # pre process payload
          # Add hardcode values into payload
          record["data"] ||= {}
          record["data"]["type"] = sync_config.stream.name
          args = [request_method, url, record]

          response = Outhad::Integrations::Core::HttpClient.request(
            url,
            request_method,
            payload: record,
            headers: auth_headers(connection_config["private_api_key"])
          )
          if success?(response)
            write_success += 1
          else
            write_failure += 1
          end
          log_message_array << log_request_response("info", args, response)
        rescue StandardError => e
          handle_exception(e, {
                             context: "KLAVIYO:RECORD:WRITE:FAILURE",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
          write_failure += 1
          log_message_array << log_request_response("error", args, e.message)
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        # TODO: Handle rate limiting seperately
        handle_exception(e, {
                           context: "KLAVIYO:RECORD:WRITE:FAILURE",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def parse_response(response)
        if success?(response)
          ConnectionStatus.new(
            status: ConnectionStatusType["succeeded"]
          ).to_outhad_message
        else
          message = extract_message(response)
          ConnectionStatus.new(
            status: ConnectionStatusType["failed"], message: message
          ).to_outhad_message
        end
      end

      def success?(response)
        response && %w[200 201].include?(response.code)
      end

      def extract_message(response)
        JSON.parse(response.body)["message"]
      rescue StandardError => e
        "Klaviyo auth failed: #{e.message}"
      end

      def auth_headers(api_key)
        {
          "Accept" => "application/json",
          "Authorization" => "Klaviyo-API-Key #{api_key}",
          "Revision" => "2023-02-22",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
