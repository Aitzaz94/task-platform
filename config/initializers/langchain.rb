# config/initializers/langchain.rb
require 'httparty'

class GroqLLM
  include HTTParty
  base_uri 'https://api.groq.com/openai/v1'

  def initialize(api_key:, model: 'llama-3.3-70b-versatile')
    @api_key = api_key
    @model = model
  end

  def complete(prompt:, max_tokens: 1000)
    response = self.class.post(
      '/chat/completions',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: @model,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: max_tokens
      }.to_json
    )
    if response.success?
      response.parsed_response.dig('choices', 0, 'message', 'content')
    else
      Rails.logger.error "Groq error: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "Groq error: #{e.message}"
    nil
  end
end

$langchain_llm = GroqLLM.new(
  api_key: ENV['GROQ_API_KEY'],
  model: 'llama-3.3-70b-versatile'
)
