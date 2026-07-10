# app/models/graph_task.rb
require 'securerandom'

class GraphTask
  attr_reader :props

  def initialize(props)
    @props = props
  end

  def id
    @props['id'] || @props[:id]
  end

  def title
    @props['title'] || @props[:title]
  end

  def description
    @props['description']
  end

  def due_date
    @props['due_date']
  end

  def priority
    @props['priority']
  end

  def status
    @props['status']
  end

  def completed
    @props['completed']
  end

  def self.create!(title:, description: nil, due_date: nil, priority: 0, creator_email: nil)
    creator = GraphUser.find_by_email(creator_email) if creator_email
    creator ||= GraphUser.first
    unless creator
      raise 'No creator user found'
    end

    task_id = SecureRandom.uuid

    cypher = <<~CYPHER
      MATCH (creator:GraphUser {email: $creator_email})
      CREATE (t:GraphTask {
        id: $task_id,
        title: $title,
        description: $description,
        due_date: $due_date,
        priority: $priority,
        status: 'open',
        completed: false,
        created_at: datetime()
      })
      CREATE (creator)-[:created]->(t)
      RETURN t
    CYPHER

    params = {
      creator_email: creator.email,
      task_id: task_id,
      title: title,
      description: description,
      due_date: due_date,
      priority: priority
    }

    result = Neo4jService.query(cypher, params)
    raise 'Task creation failed' if result.empty?
    new(result.first['t'])
  end

  def self.find(task_id)
    result = Neo4jService.query('MATCH (t:GraphTask {id: $id}) RETURN t', id: task_id)
    return nil if result.empty?
    new(result.first['t'])
  end

  def self.first
    result = Neo4jService.query('MATCH (t:GraphTask) RETURN t LIMIT 1')
    return nil if result.empty?
    new(result.first['t'])
  end
end
