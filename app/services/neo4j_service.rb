# app/services/neo4j_service.rb
require 'httparty'
require 'json'

class Neo4jService
  include HTTParty

  base_uri ENV.fetch('NEO4J_URL', 'http://localhost:7474')
  basic_auth ENV.fetch('NEO4J_USER', 'neo4j'), ENV.fetch('NEO4J_PASSWORD', 'password')
  headers 'Content-Type' => 'application/json'

  # Execute a Cypher query and return the raw parsed response
  def self.execute_query(cypher, params = {})
    body = {
      statements: [
        {
          statement: cypher,
          parameters: params
        }
      ]
    }
    # Use the correct endpoint for your Neo4j version
    response = post('/db/neo4j/tx/commit', body: body.to_json)
    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Neo4j query failed: #{response.body}"
      raise "Neo4j error: #{response.code} - #{response.body}"
    end
  end

  # Execute a query and return an array of hashes
  # Each hash has keys = column names, values = the row data
  def self.query(cypher, params = {})
    result = execute_query(cypher, params)
    data = result.dig('results', 0, 'data') || []
    columns = result.dig('results', 0, 'columns') || []
    data.map do |row|
      # row['row'] is an array of values; zip with column names
      Hash[columns.zip(row['row'])]
    end
  end
end
