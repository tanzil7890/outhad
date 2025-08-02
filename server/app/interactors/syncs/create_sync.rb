# frozen_string_literal: true

module Syncs
  class CreateSync
    include Interactor

    def call
      sync = context
             .workspace.syncs
             .create(context.sync_params)
      if sync.persisted?
        context.sync = sync
      else
        context.fail!(sync:)
      end
    end
  end
end
