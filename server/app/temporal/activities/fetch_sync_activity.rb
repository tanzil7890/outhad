# frozen_string_literal: true

module Activities
  class FetchSyncActivity < Temporal::Activity
    class SyncNotFound < Temporal::ActivityException; end
    retry_policy(
      interval: 1,
      backoff: 1,
      max_attempts: 3
    )

    def execute(sync_id)
      sync = Sync.find_by(id: sync_id)
      raise SyncNotFound, "Sync with specified ID does not exist" unless sync

      sync
    end
  end
end
