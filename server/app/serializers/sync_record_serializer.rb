# frozen_string_literal: true

class SyncRecordSerializer < ActiveModel::Serializer
  attributes :id, :sync_id, :sync_run_id, :record, :status, :action,
             :logs, :created_at, :updated_at
end
