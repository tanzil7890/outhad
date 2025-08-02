# frozen_string_literal: true

# spec/support/auth_helper.rb
module AuthHelper
  def auth_headers(user, workspace_id)
    # Directly generate the token without going through login process
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.update!(jti: payload["jti"])

    {
      "Authorization" => "Bearer #{token}",
      "Workspace-Id" => workspace_id
    }
  end
end
