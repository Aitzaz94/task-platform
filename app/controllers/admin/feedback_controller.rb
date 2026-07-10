module Admin
  class FeedbackController < ApplicationController
    before_action :check_admin

    def index
      @feedbacks = TaskFeedback.includes(:user).order(created_at: :desc).page(params[:page])
    end

    private

    def check_admin
      # Basic check: current_user.email == 'admin@example.com'
      render plain: 'Forbidden', status: 403 unless current_user.email == 'admin@example.com'
    end
  end
end
