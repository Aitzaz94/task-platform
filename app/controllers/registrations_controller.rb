# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  skip_before_action :authenticate, only: [:create]

  def create
    user = User.new(user_params)
    if user.save
      render json: { token: user.token, email: user.email }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
