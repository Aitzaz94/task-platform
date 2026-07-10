# app/agents/tools/neo4j_tools.rb
module Neo4jTools
  extend self

  def create_task(title:, description: nil, due_date: nil, priority: 0, creator_email: nil, assignee_emails: [])
    # Find the creator
    creator = GraphUser.find_by_email(creator_email) if creator_email
    creator ||= GraphUser.first

    unless creator
      return { success: false, error: 'No creator user found' }
    end

    # Create the task
    task = GraphTask.create!(
      title: title,
      description: description,
      due_date: due_date,
      priority: priority,
      creator_email: creator.email
    )

    # Add assignees (if any)
    assignee_emails.each do |email|
      assignee = GraphUser.find_by_email(email)
      if assignee
        Neo4jService.execute_query(
          'MATCH (t:GraphTask {id: $task_id}), (u:GraphUser {email: $email})
           CREATE (u)-[:assigned_to]->(t)',
          task_id: task.id,
          email: email
        )
      end
    end

    # --- Webhook notification (only on success) ---
    if ENV['N8N_TASK_CREATED_WEBHOOK'].present?
      payload = {
        task: {
          id: task.id,
          title: task.title,
          description: task.description,
          due_date: task.due_date,
          priority: task.priority,
          creator: creator.email
        }
      }
      HTTParty.post(ENV['N8N_TASK_CREATED_WEBHOOK'],
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    { success: true, task_id: task.id, title: task.title }
  rescue => e
    { success: false, error: e.message }
  end

  def query_tasks(status: nil, priority: nil, completed: nil, assignee_email: nil)
    # Build a dynamic Cypher query
    conditions = []
    params = {}
    if status
      conditions << 't.status = $status'
      params[:status] = status
    end
    if priority
      conditions << 't.priority = $priority'
      params[:priority] = priority
    end
    unless completed.nil?
      conditions << 't.completed = $completed'
      params[:completed] = completed
    end
    if assignee_email
      # We need to match tasks assigned to that user
      conditions << '(:GraphUser {email: $assignee_email})-[:assigned_to]->(t)'
      params[:assignee_email] = assignee_email
    end

    where_clause = conditions.empty? ? '' : "WHERE #{conditions.join(' AND ')}"
    cypher = "MATCH (t:GraphTask) #{where_clause} RETURN t LIMIT 50"

    result = Neo4jService.query(cypher, params)
    result.map do |record|
      task = record['t']
      {
        id: task['id'],
        title: task['title'],
        status: task['status'],
        priority: task['priority'],
        due_date: task['due_date']
      }
    end
  end

  def update_task(task_id, attributes)
    # Build SET clause dynamically
    set_parts = []
    params = { task_id: task_id }
    attributes.each do |key, value|
      set_parts << "t.#{key} = $#{key}"
      params[key.to_sym] = value
    end
    return { success: false, error: 'No attributes to update' } if set_parts.empty?

    cypher = "MATCH (t:GraphTask {id: $task_id}) SET #{set_parts.join(', ')} RETURN t"
    result = Neo4jService.query(cypher, params)
    if result.empty?
      { success: false, error: 'Task not found' }
    else
      { success: true, task_id: task_id }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def find_related(task_id)
    cypher = <<~CYPHER
      MATCH (t:GraphTask {id: $task_id})
      OPTIONAL MATCH (t)-[:blocks]->(blocked:GraphTask)
      OPTIONAL MATCH (blocker:GraphTask)-[:blocks]->(t)
      RETURN t, blocked, blocker
    CYPHER
    result = Neo4jService.query(cypher, task_id: task_id)
    return { error: "Task #{task_id} not found" } if result.empty?

    blockers = []
    blocking = []
    result.each do |row|
      # row['blocked'] and row['blocker'] may be nil or have properties
      if row['blocked']
        blockers << { id: row['blocked']['id'], title: row['blocked']['title'] }
      end
      if row['blocker']
        blocking << { id: row['blocker']['id'], title: row['blocker']['title'] }
      end
    end

    # Remove duplicates (the query can return multiple rows if there are multiple relationships)
    blockers.uniq!
    blocking.uniq!

    { blockers: blockers, blocking: blocking }
  rescue => e
    { error: e.message }
  end

  def record_feedback(task_id, user_email, rating, comments = nil)
    # This uses the PostgreSQL User model (since feedback is stored in PostgreSQL)
    user = User.find_by(email: user_email)
    return { success: false, error: 'User not found' } unless user

    feedback = TaskFeedback.create!(
      task_graph_id: task_id,
      user_id: user.id,
      satisfaction: rating,
      comments: comments,
      actual_duration: nil
    )
    { success: true, feedback_id: feedback.id }
  rescue => e
    { success: false, error: e.message }
  end
end