# frozen_string_literal: true

module Outhad
  module Integrations
    module Destination
      module Zendesk
        include Outhad::Integrations::Core
        class Client < DestinationConnector
          prepend Outhad::Integrations::Core::RateLimiter
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            handle_exception(e, {
                               context: "ZENDESK:CHECK_CONNECTION:EXCEPTION",
                               type: "error"
                             })
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_outhad_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "ZENDESK:DISCOVER:EXCEPTION",
                               type: "error"
                             })
            failure_status(e)
          end

          def write(sync_config, records, action = "create")
            @sync_config = sync_config
            @action = sync_config.stream.action || action
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "ZENDESK:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
            failure_status(e)
          end

          private

          def initialize_client(connection_config)
            connection_config = connection_config.with_indifferent_access
            @client = ZendeskAPI::Client.new do |config|
              config.url = "#{connection_config[:subdomain]}.#{ZENDESK_URL_SUFFIX}"
              config.username = connection_config[:username]
              config.password = connection_config[:password]
            end
          end

          def authenticate_client
            @client.tickets.page(1).per_page(1).fetch
          rescue ZendeskAPI::Error => e
            raise StandardError, "Authentication failed: #{e.message}"
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0

            records.each do |record|
              zendesk_data = prepare_record_data(record, stream.name)
              plural_stream_name = pluralize_stream_name(stream.name.downcase)
              args = [plural_stream_name, @action, zendesk_data]

              if @action == "create"
                response = @client.send(plural_stream_name).create!(zendesk_data)
              else
                existing_record = @client.send(plural_stream_name).find(id: record[:id])
                response = existing_record.update!(zendesk_data)
              end

              write_success += 1
              log_message_array << log_request_response("info", args, response)
            rescue StandardError => e
              handle_exception(e, {
                                 context: "ZENDESK:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: @sync_config.sync_id,
                                 sync_run_id: @sync_config.sync_run_id
                               })
              write_failure += 1
              log_message_array << log_request_response("error", args, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def pluralize_stream_name(name)
            { "ticket" => "tickets", "user" => "users" }.fetch(name, name)
          end

          def prepare_record_data(record, type)
            case type
            when "Tickets"
              {
                subject: record[:subject],
                comment: { body: record[:description] },
                priority: record[:priority],
                status: record[:status],
                requester_id: record[:requester_id],
                assignee_id: record[:assignee_id],
                tags: record[:tags]
              }
            when "Users"
              {
                name: record[:name],
                email: record[:email],
                role: record[:role]
              }
            else
              raise StandardError, "Unsupported record type: #{type}"
            end
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end
        end
      end
    end
  end
end
