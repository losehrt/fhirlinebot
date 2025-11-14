module RequestHelpers
  def json
    JSON.parse(response.body)
  end

  def auth_headers(user)
    {
      'Authorization' => "Bearer #{user.authentication_token}"
    }
  end

  def line_webhook_header(signature)
    {
      'X-Line-Signature' => signature,
      'Content-Type' => 'application/json'
    }
  end

  def sign_in_as(user)
    # Set user_id in session by making a dummy request that establishes the session
    post auth_logout_path  # Make a request to establish session first
    # Now set the user_id in the session
    session[:user_id] = user.id
  end

  def expect_success
    expect(response).to have_http_status(:success)
  end

  def expect_created
    expect(response).to have_http_status(:created)
  end

  def expect_unauthorized
    expect(response).to have_http_status(:unauthorized)
  end

  def expect_forbidden
    expect(response).to have_http_status(:forbidden)
  end

  def expect_not_found
    expect(response).to have_http_status(:not_found)
  end

  def expect_unprocessable_entity
    expect(response).to have_http_status(:unprocessable_entity)
  end
end