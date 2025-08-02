# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  default from: Rails.configuration.x.mail_from

  def invitation_instructions(record, token, opts = {})
    @workspace = opts[:workspace]
    @role = opts[:role]
    @is_verified = opts[:is_verified] || false
    @token = token
    super
  end
end
