source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'
gem 'bootsnap', '~> 1.16', require: false
gem 'langfuse', '~> 0.1.1'
gem 'connection_pool', '~> 2.4.1'

gem 'rails', '~> 7.0.8'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.0'
gem 'bcrypt', '~> 3.1.7'

# Graph Database

#------------

# gem 'google-genai', '~> 0.1.1'
# gem 'google-apis-generativeai', '~> 0.45.0'


# AI & LangChain
gem 'langchainrb', '~> 0.6.0'
gem 'langgraph_rb', '~> 0.1.0'
gem 'anthropic', '~> 0.2.0'

# Background
gem 'sidekiq', '~> 7.0'
# gem 'sidekiq', '~> 6.5.0'
gem 'redis', '~> 5.0'

# HTTP & JSON
gem 'httparty', '~> 0.21.0'
gem 'dotenv-rails', '~> 2.8'
gem 'rack-cors', '~> 2.0'
gem 'kaminari', '~> 1.2'
gem 'image_processing', '~> 1.2'

# Twilio (optional, for later)
gem 'twilio-ruby', '~> 6.0'

group :development, :test do
  gem 'debug'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  gem 'spring'
end