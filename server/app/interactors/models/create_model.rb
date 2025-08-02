# frozen_string_literal: true

module Models
  class CreateModel
    include Interactor

    def call
      model = context
              .connector.models
              .create(context.model_params)

      if model.persisted?
        context.model = model
      else
        context.fail!(model:)
      end
    end
  end
end
