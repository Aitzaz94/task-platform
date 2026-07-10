class PlanningWorker
  include Sidekiq::Worker

  def perform(user_id, request_text)
    user = User.find(user_id)
    agent = TaskPlannerAgent.new
    result = agent.process(request_text, user_email: user.email)

    # Store result in Redis for polling
    Redis.current.set("planning_result:#{user_id}", result.to_json, ex: 3600)

    # Optionally call n8n for further automation
    if result[:tasks].any?
      HTTParty.post(ENV['N8N_TASK_CREATED_WEBHOOK'],
        body: { user: user.email, tasks: result[:tasks] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end
  rescue => e
    Rails.logger.error "PlanningWorker error: #{e.message}"
  end
end
