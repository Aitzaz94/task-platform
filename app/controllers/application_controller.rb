class ApplicationController < ActionController::API
    before_action :authenticate

  private

  def authenticate
    header = request.headers['Authorization']
    token = header&.split(' ')&.last
    @current_user = User.find_by(token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  attr_reader :current_user
end
