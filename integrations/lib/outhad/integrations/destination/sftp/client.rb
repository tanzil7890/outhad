# frozen_string_literal: true

module Outhad::Integrations::Destination
  module Sftp
    include Outhad::Integrations::Core
    class Client < DestinationConnector
      prepend Outhad::Integrations::Core::Fullrefresher
      prepend Outhad::Integrations::Core::RateLimiter

      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        with_sftp_client(connection_config) do |sftp|
          stream = SecureRandom.uuid
          test_path = "#{connection_config[:destination_path]}/#{stream}"
          test_file_operations(sftp, test_path)
          return success_status
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "SFTP:CHECK_CONNECTION:EXCEPTION",
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
                           context: "SFTP:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        @sync_config = sync_config
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        file_path = generate_file_path(sync_config)
        local_file_name = generate_local_file_name(sync_config)
        csv_content = generate_csv_content(records)
        records_size = records.size
        write_success = 0

        case connection_config[:format][:compression_type]
        when CompressionType.enum("zip")
          write_success = write_compressed_data(connection_config, file_path, local_file_name, csv_content, records_size)
        when CompressionType.enum("un_compressed")
          write_success = write_uncompressed_data(connection_config, file_path, local_file_name, csv_content, records_size)
        else
          raise ArgumentError, "Unsupported compression type: #{connection_config[:format][:compression_type]}"
        end
        write_failure = records.size - write_success
        tracking_message(write_success, write_failure)
      rescue StandardError => e
        handle_exception(e, {
                           context: "SFTP:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: @sync_config.sync_id,
                           sync_run_id: @sync_config.sync_run_id
                         })
      end

      def write_compressed_data(connection_config, file_path, local_file_name, csv_content, records_size)
        write_success = 0
        Tempfile.create([local_file_name, ".zip"]) do |tempfile|
          Zip::File.open(tempfile.path, Zip::File::CREATE) do |zipfile|
            zipfile.get_output_stream("#{local_file_name}.csv") { |f| f.write(csv_content) }
          end
          with_sftp_client(connection_config) do |sftp|
            sftp.upload!(tempfile.path, file_path)
            write_success = records_size
          rescue StandardError => e
            # TODO: add sync_id and sync_run_id to the log
            handle_exception(e, {
                               context: "SFTP:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
            write_success = 0
          end
        end
        write_success
      end

      def write_uncompressed_data(connection_config, file_path, local_file_name, csv_content, records_size)
        write_success = 0
        Tempfile.create([local_file_name, ".csv"]) do |tempfile|
          tempfile.write(csv_content)
          tempfile.close
          with_sftp_client(connection_config) do |sftp|
            sftp.upload!(tempfile.path, file_path)
            write_success = records_size
          rescue StandardError => e
            # TODO: add sync_id and sync_run_id to the log
            handle_exception(e, {
                               context: "SFTP:RECORD:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
            write_success = 0
          end
        end
        write_success
      end

      def clear_all_records(sync_config)
        connection_specification = sync_config.destination.connection_specification.with_indifferent_access
        with_sftp_client(connection_specification) do |sftp|
          files = sftp.dir.glob(connection_specification[:destination_path], "*")
          files.each do |file|
            sftp.remove!(File.join(connection_specification[:destination_path], file.name))
          end
          return control_message("Successfully cleared data.", "succeeded") if sftp.dir.entries(connection_specification[:destination_path]).size <= 2

          return control_message("Failed to clear data.", "failed")
        end
      rescue StandardError => e
        control_message(e.message, "failed")
      end

      private

      def generate_file_path(sync_config)
        connection_specification = sync_config.destination.connection_specification.with_indifferent_access
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
        format = connection_specification[:format]
        extension = if format[:compression_type] == "un_compressed"
                      format[:format_type]
                    else
                      format[:compression_type]
                    end
        file_name = "#{connection_specification[:file_name]}_#{timestamp}.#{extension}"
        File.join(connection_specification[:destination_path], file_name)
      end

      def generate_local_file_name(sync_config)
        connection_specification = sync_config.destination.connection_specification.with_indifferent_access
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
        "#{connection_specification[:file_name]}_#{timestamp}"
      end

      def generate_csv_content(records)
        CSV.generate do |csv|
          headers = records.first.keys
          csv << headers
          records.each { |record| csv << record.values_at(*headers) }
        end
      end

      def tracking_message(success, failure)
        Outhad::Integrations::Protocol::TrackingMessage.new(
          success: success, failed: failure
        ).to_outhad_message
      end

      def with_sftp_client(connection_config, &block)
        Net::SFTP.start(
          connection_config[:host],
          connection_config[:username],
          password: connection_config[:password],
          port: connection_config.fetch(:port, 22), &block
        )
      end

      def test_file_operations(sftp, test_path)
        sftp.file.open(test_path, "w") { |file| file.puts("connection_check") }
        sftp.remove!(test_path)
      end

      def control_message(message, status)
        ControlMessage.new(
          type: "full_refresh",
          emitted_at: Time.now.to_i,
          status: ConnectionStatusType[status],
          meta: { detail: message }
        ).to_outhad_message
      end
    end
  end
end
