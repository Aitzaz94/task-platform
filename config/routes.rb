Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  post '/register', to: 'registrations#create'
  post '/login', to: 'sessions#create'

  post '/ai/plan', to: 'ai#plan_tasks'
  get '/ai/tasks', to: 'ai#query_tasks'
  post '/ai/feedback', to: 'ai#feedback'

  post '/ai/plan_async', to: 'ai#plan_tasks_async'
  get '/ai/status', to: 'ai#status'

end
