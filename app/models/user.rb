# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  before_create :generate_token
  after_create :sync_to_neo4j

  validates :email, presence: true, uniqueness: true

  private

  def generate_token
    self.token = SecureRandom.hex(20)
  end

  def sync_to_neo4j
    GraphUser.create!(external_id: id, email: email)
  rescue => e
    Rails.logger.error "Neo4j sync failed for user #{id}: #{e.message}"
  end
end
