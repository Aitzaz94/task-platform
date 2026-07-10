# app/models/graph_user.rb
class GraphUser
  attr_reader :props

  def initialize(props)
    @props = props
  end

  def id
    @props['id'] || @props[:id]
  end

  def external_id
    @props['external_id'] || @props[:external_id]
  end

  def email
    @props['email'] || @props[:email]
  end

  def self.find_by_email(email)
    result = Neo4jService.query(
      'MATCH (u:GraphUser {email: $email}) RETURN u',
      email: email
    )
    return nil if result.empty?
    new(result.first['u'])
  end

  def self.find_by_external_id(external_id)
    result = Neo4jService.query(
      'MATCH (u:GraphUser {external_id: $external_id}) RETURN u',
      external_id: external_id
    )
    return nil if result.empty?
    new(result.first['u'])
  end

  def self.first
    result = Neo4jService.query('MATCH (u:GraphUser) RETURN u LIMIT 1')
    return nil if result.empty?
    new(result.first['u'])
  end

  def self.create!(external_id:, email:)
    result = Neo4jService.query(
      'CREATE (u:GraphUser {external_id: $external_id, email: $email, created_at: datetime()}) RETURN u',
      external_id: external_id,
      email: email
    )
    new(result.first['u'])
  end
end
