FactoryBot.define do
  factory :task_feedback do
    task_graph_id { 1 }
    user_id { 1 }
    actual_duration { 1.5 }
    satisfaction { 1 }
    comments { "MyText" }
  end
end
