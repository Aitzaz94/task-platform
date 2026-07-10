class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [:create]

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      user.update(token: SecureRandom.hex(20)) if user.token.blank?
      render json: { token: user.token, email: user.email }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end
end
