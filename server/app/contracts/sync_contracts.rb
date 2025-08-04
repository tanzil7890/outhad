# frozen_string_literal: true

module SyncContracts
  class Index < Dry::Validation::Contract
    params do
      optional(:page).filled(:integer)
    end
  end

  class Show < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Create < Dry::Validation::Contract
    params do
      required(:sync).hash do
        optional(:name).filled(:string)
        optional(:source_id).filled(:integer)
        required(:model_id).filled(:integer)
        required(:destination_id).filled(:integer)
        required(:schedule_type).filled(:string)
        optional(:sync_interval).maybe(:integer)
        optional(:sync_interval_unit).maybe(:string)
        optional(:cron_expression).maybe(:string)
        required(:sync_mode).filled(:string)
        required(:stream_name).filled(:string)
        optional(:cursor_field).maybe(:string)

        # update filled with validating array of hashes
        required(:configuration).filled
      end
    end

    # TODO: Enable this once we have implemented frontend for adding names to syncs
    # rule(sync: :name) do
    #   key.failure("sync name must be present") if value.to_s.strip.empty?
    # end

    rule(sync: :sync_mode) do
      key.failure("invalid sync mode") unless Sync.sync_modes.keys.include?(value.downcase)
    end

    rule(sync: :schedule_type) do
      key.failure("invalid schedule type") unless Sync.schedule_types.keys.include?(value.downcase)
    end

    rule(sync: :sync_interval) do
      schedule_type = values.dig(:sync, :schedule_type)
      next unless schedule_type == "interval"

      if value.nil?
        key.failure("must be present")
      elsif value <= 0
        key.failure("must be greater than 0")
      end
    end

    rule(sync: :sync_interval_unit) do
      schedule_type = values.dig(:sync, :schedule_type)
      next unless schedule_type == "interval"

      if value.nil?
        key.failure("must be present")
      else
        key.failure("invalid sync interval unit") unless Sync.sync_interval_units.keys.include?(value.downcase)
      end
    end

    rule(sync: :cron_expression) do
      schedule_type = values.dig(:sync, :schedule_type)
      next unless schedule_type == "cron_expression"

      if value.nil?
        key.failure("must be present")
      elsif Fugit::Cron.new(value).nil?
        key.failure("invalid cron expression format")
      end
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:sync).hash do
        optional(:source_id).filled(:integer)
        optional(:model_id).filled(:integer)
        optional(:destination_id).filled(:integer)
        optional(:schedule_type).filled(:string)
        optional(:sync_interval).maybe(:integer)
        optional(:sync_interval_unit).maybe(:string)
        optional(:cron_expression).maybe(:string)
        optional(:sync_mode).filled(:string)
        optional(:stream_name).filled(:string)

        # update filled with validating array of hashes
        optional(:configuration).filled
      end
    end

    # TODO: Enable this once we have implemented frontend for adding names to syncs
    # rule(sync: :name) do
    #   key.failure("sync name must be present") if value.to_s.strip.empty?
    # end

    rule(sync: :sync_mode) do
      key.failure("invalid sync mode") if key? && !Sync.sync_modes.keys.include?(value.downcase)
    end

    rule(sync: :schedule_type) do
      key.failure("invalid schedule type") if key? && !Sync.schedule_types.keys.include?(value.downcase)
    end

    rule(sync: :sync_interval) do
      schedule_type = values.dig(:sync, :schedule_type)
      next unless key? && schedule_type == "interval"

      if value.nil?
        key.failure("must be present")
      elsif value <= 0
        key.failure("must be greater than 0")
      end
    end

    rule(sync: :sync_interval_unit) do
      schedule_type = values.dig(:sync, :schedule_type)
      next unless key? && schedule_type == "interval"

      if value.nil?
        key.failure("must be present")
      else
        key.failure("invalid sync interval unit") unless Sync.sync_interval_units.keys.include?(value.downcase)
      end
    end

    rule(sync: :cron_expression) do
      schedule_type = values.dig(:sync, :schedule_type)
      next unless key? && schedule_type == "cron_expression"

      if value.nil?
        key.failure("must be present")
      elsif Fugit::Cron.new(value).nil?
        key.failure("invalid cron expression format")
      end
    end
  end

  class Enable < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:enable).filled(:bool)
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Configurations < Dry::Validation::Contract
    params {}
  end
end
