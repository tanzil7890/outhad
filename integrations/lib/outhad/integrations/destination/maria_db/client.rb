# frozen_string_literal: true

module Outhad::Integrations::Destination
  module MariaDB
    include Outhad::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_outhad_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_outhad_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = '#{connection_config[:database]}'
                 ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)
        records = db.fetch(query) do |result|
          result.map do |row|
            row
          end
        end
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_outhad_message
      rescue StandardError => e
        handle_exception(
          "MARIA:DB:DISCOVER:EXCEPTION",
          "error",
          e
        )
      end

      def write(sync_config, records, action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        table_name = sync_config.stream.name
        primary_key = sync_config.model.primary_key
        db = create_connection(connection_config)

        log_message_array = []
        write_success = 0
        write_failure = 0

        records.each do |record|
          query = Outhad::Integrations::Core::QueryBuilder.perform(action, table_name, record, primary_key)
          logger.debug("MARIA:DB:WRITE:QUERY query = #{query} sync_id = #{sync_config.sync_id} sync_run_id = #{sync_config.sync_run_id}")
          begin
            db.run(query)
            write_success += 1
            log_message_array << log_request_response("info", query, "Successful")
          rescue StandardError => e
            handle_exception(e, {
                               context: "MARIA:DB:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
            write_failure += 1
            log_message_array << log_request_response("error", query, e.message)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "MARIA:DB:RECORD:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        Sequel.connect(
          adapter: "mysql2",
          host: connection_config[:host],
          port: connection_config[:port],
          user: connection_config[:username],
          password: connection_config[:password],
          database: connection_config[:database]
        )
      end

      def create_streams(records)
        group_by_table(records).map do |_, r|
          Outhad::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        result = {}
        records.each_with_index do |entry, index|
          table_name = entry[:table_name]
          column_data = {
            column_name: entry[:column_name],
            data_type: entry[:data_type],
            is_nullable: entry[:is_nullable] == "YES"
          }
          result[index] ||= {}
          result[index][:tablename] = table_name
          result[index][:columns] = [column_data]
        end
        result.values.group_by { |entry| entry[:tablename] }.transform_values do |entries|
          { tablename: entries.first[:tablename], columns: entries.flat_map { |entry| entry[:columns] } }
        end
      end
    end
  end
end
