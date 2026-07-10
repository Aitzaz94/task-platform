# app/agents/task_planner_agent.rb
require 'json'

class TaskPlannerAgent
  attr_reader :state

  def initialize
    @llm = $langchain_llm
    @tools = Neo4jTools
  end

  def process(user_request, user_email: nil, max_loops: 3)
    @state = {
      user_request: user_request,
      user_email: user_email,
      plan: nil,
      tasks: [],
      feedback: [],
      reflection: nil,
      loop_count: 0,
      max_loops: max_loops,
      completed: false,
      summary: nil
    }

    # Initial understanding
    understand_request

    # Planning loop
    loop do
      create_plan
      break unless should_execute?
      execute_plan
      collect_feedback
      break unless should_continue?
      reflect
      @state[:loop_count] += 1
    end

    summarize
    @state
  end

  private

def understand_request
  prompt = <<~PROMPT
    You are a task planning assistant. Analyze the following user request and extract:
    - The main goal of the request.
    - A list of subtasks (each with title, description, priority, due date if mentioned).
    - Any dependencies between subtasks.
    - Any specific constraints (e.g., team size, deadlines).

    User request: "#{@state[:user_request]}"

    Return a JSON object with keys: "main_goal", "subtasks" (array of objects with "title", "description", "priority", "due_date"), "dependencies" (array of objects with "from" and "to" subtask titles).
  PROMPT

  response = @llm.complete(prompt: prompt, max_tokens: 1000)
  if response.nil? || response.empty?
    Rails.logger.warn "LLM failed – using fallback dummy plan"
    @state[:plan] = {
      'main_goal' => 'Fallback: Create sample tasks',
      'subtasks' => [
        { 'title' => 'Task 1', 'description' => 'Sample task 1', 'priority' => 1 },
        { 'title' => 'Task 2', 'description' => 'Sample task 2', 'priority' => 2 }
      ],
      'dependencies' => []
    }
  else
    @state[:plan] = parse_response(response)
  end
end

  def create_plan
    # If we have reflection, adjust the plan
    if @state[:reflection]
      adjusted = adjust_plan_with_reflection(@state[:plan], @state[:reflection])
      @state[:plan] = adjusted
    end
    # plan is already in state
  end

  def should_execute?
    @state[:plan] && @state[:plan]['subtasks'] && @state[:plan]['subtasks'].any?
  end

  def execute_plan
    subtasks = @state[:plan]['subtasks'] || []
    created = []
    user_email = @state[:user_email]

    subtasks.each do |subtask|
      result = @tools.create_task(
        title: subtask['title'],
        description: subtask['description'],
        due_date: subtask['due_date'],
        priority: subtask['priority'] || 0,
        creator_email: user_email
      )
      created << result
    end

    # Record dependencies (optional)
    deps = @state[:plan]['dependencies'] || []
    deps.each do |dep|
      from = created.find { |t| t[:title] == dep['from'] }
      to = created.find { |t| t[:title] == dep['to'] }
      if from && to
        begin
          task_from = GraphTask.find(from[:task_id])
          task_to = GraphTask.find(to[:task_id])
          task_from.blocks << task_to
        rescue => e
          Rails.logger.error "Dependency error: #{e.message}"
        end
      end
    end

    @state[:tasks] = created
  end

  def collect_feedback
  task_list = @state[:tasks].map { |t| "- #{t[:title]}" }.join("\n")
  feedback_prompt = <<~PROMPT
    You have just created these tasks:
    #{task_list}

    Based on the user's request and typical outcomes, provide an estimated satisfaction rating (1-5) and any comments about the plan's quality.
    Return JSON: {"rating": integer, "comments": "string"}
  PROMPT

  response = @llm.complete(prompt: feedback_prompt, max_tokens: 200)
  feedback_data = JSON.parse(response) rescue { 'rating' => 3, 'comments' => 'Average' }

  # Use positional arguments, not keywords
  @tools.record_feedback(
    @state[:tasks].first[:task_id],
    @state[:user_email],
    feedback_data['rating'],
    feedback_data['comments']
  )

  @state[:feedback] << feedback_data
end

  def should_continue?
    avg_rating = @state[:feedback].sum { |f| f['rating'] }.to_f / @state[:feedback].size rescue 0
    avg_rating < 3.5 && @state[:loop_count] < @state[:max_loops]
  end

  def reflect
    feedback_text = @state[:feedback].map do |f|
      "Rating: #{f['rating']}, Comments: #{f['comments']}"
    end.join("\n")

    reflection_prompt = <<~PROMPT
      You previously created a plan and received this feedback:
      #{feedback_text}

      How would you adjust your planning strategy for future requests? Provide a short strategy update.
    PROMPT

    strategy = @llm.complete(prompt: reflection_prompt, max_tokens: 300)
    @state[:reflection] = strategy
  end

  def summarize
    summary_prompt = <<~PROMPT
      Summarize the planning process. You created #{@state[:tasks].size} tasks. Final reflection: #{@state[:reflection]}.
      Provide a brief summary for the user.
    PROMPT
    summary = @llm.complete(prompt: summary_prompt, max_tokens: 200)
    @state[:summary] = summary
    @state[:completed] = true
  end

  def adjust_plan_with_reflection(plan, reflection)
    prompt = <<~PROMPT
      Given the original plan: #{plan.to_json}
      And the reflection: #{reflection}
      Adjust the plan (subtasks, priorities, etc.) to improve outcomes.
      Return the new plan in the same JSON format as before.
    PROMPT
    response = @llm.complete(prompt: prompt, max_tokens: 1000)
    parse_response(response)
  end

  def parse_response(response)
  return { 'main_goal' => 'No response from LLM', 'subtasks' => [], 'dependencies' => [] } if response.nil? || response.empty?

  json_match = response.match(/```json\s*(\{.*?\})\s*```/m) || response.match(/(\{.*\})/m)
  if json_match
    JSON.parse(json_match[1])
  else
    { 'main_goal' => response, 'subtasks' => [], 'dependencies' => [] }
  end
rescue JSON::ParserError
  { 'main_goal' => 'Parsing error', 'subtasks' => [], 'dependencies' => [] }
end
end
