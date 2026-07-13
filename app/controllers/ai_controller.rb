class AiController < ApplicationController
  def plan_tasks
    agent = TaskPlannerAgent.new
    result = agent.process(params[:request], user_email: current_user.email, max_loops: 3)

    render json: {
      summary: result[:summary],
      tasks_created: result[:tasks].select { |t| t[:success] },
      feedback: result[:feedback],
      reflection: result[:reflection],
      completed: result[:completed]
    }, status: :ok
  rescue => e
    render json: { error: e.message, backtrace: e.backtrace.first(5) }, status: :internal_server_error
  end

  def query_tasks
    filters = params.permit(:status, :priority, :completed, :assignee_email)
    tasks = Neo4jTools.query_tasks(**filters)
    render json: tasks
  end

  def feedback
    # Endpoint to receive feedback from frontend/chat
    # POST /ai/feedback with { task_id: id, rating: 4, comments: "..." }
    result = Neo4jTools.record_feedback(
      params[:task_id],
      current_user.email,
      params[:rating],
      params[:comments]
    )
    render json: result
  end


  def plan_tasks_async
  job_id = PlanningWorker.perform_async(current_user.id, params[:request])
  render json: { job_id: job_id, message: 'Planning started. Poll /ai/status for result.' }
end

def status
  data = Sidekiq.redis { |conn| conn.get("planning_result:#{current_user.id}") }
  if data
    render json: JSON.parse(data)
  else
    render json: { status: 'processing' }
  end
end

end
